package com.zzz.core.domain.couple;

import com.zzz.core.api.dto.CoupleInviteResponse;
import com.zzz.core.api.dto.PartnerStatusResponse;
import com.zzz.core.domain.user.User;
import com.zzz.core.domain.user.UserRepository;
import com.zzz.core.domain.user.UserStatusService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CoupleService {

    private final CoupleRepository coupleRepository;
    private final UserRepository userRepository;
    private final UserStatusService userStatusService;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final String INVITE_CODE_PREFIX = "couple:invite:";
    private static final String USER_METADATA_KEY_PREFIX = "user:metadata:";
    private static final long INVITE_CODE_TTL_HOURS = 24;

    /**
     * 상대방 상태 조회
     */
    @Transactional(readOnly = true)
    public PartnerStatusResponse getPartnerStatus(Long userId) {
        User me = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (me.getCoupleId() == null) {
            throw new IllegalStateException("User is not in a couple");
        }

        Couple couple = coupleRepository.findById(me.getCoupleId())
                .orElseThrow(() -> new IllegalStateException("Couple info not found"));

        Long partnerId = couple.getUserAId().equals(userId) ? couple.getUserBId() : couple.getUserAId();
        User partner = userRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalStateException("Partner user not found"));

        // Redis Metadata (Battery)
        String metaKey = USER_METADATA_KEY_PREFIX + partnerId;
        Map<Object, Object> metadata = redisTemplate.opsForHash().entries(metaKey);
        
        Integer battery = null;
        if (metadata.containsKey("battery")) {
            Object batteryObj = metadata.get("battery");
            if (batteryObj instanceof String) {
                try {
                    battery = Integer.parseInt((String) batteryObj);
                } catch (NumberFormatException e) {
                    // Ignore or log invalid format
                }
            } else if (batteryObj instanceof Integer) {
                battery = (Integer) batteryObj;
            }
        }

        return PartnerStatusResponse.builder()
                .userId(partner.getId())
                .nickname(partner.getNickname())
                .status(partner.getStatus()) // Or userStatusService.getUserStatus(partnerId) if real-time priority
                .lastActiveAt(partner.getLastActiveAt())
                .batteryLevel(battery)
                .build();
    }

    /**
     * 초대 코드 생성
     * Redis에 저장: Key=code, Value=userId
     */
    public CoupleInviteResponse createInviteCode(Long userId) {
        // 이미 커플인지 확인
        User user = userRepository.findById(userId).orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (user.getCoupleId() != null) {
            throw new IllegalStateException("User is already in a couple");
        }

        String code = UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String key = INVITE_CODE_PREFIX + code;
        
        // Value에 UserId 저장
        redisTemplate.opsForValue().set(key, userId.toString(), Duration.ofHours(INVITE_CODE_TTL_HOURS));

        return new CoupleInviteResponse(code, Duration.ofHours(INVITE_CODE_TTL_HOURS).toSeconds());
    }

    /**
     * 초대 코드 입력하여 커플 연결
     */
    @Transactional
    public Long connectCouple(Long userId, String code) {
        User me = userRepository.findById(userId).orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (me.getCoupleId() != null) {
            throw new IllegalStateException("User is already in a couple");
        }

        String key = INVITE_CODE_PREFIX + code;
        String partnerIdStr = (String) redisTemplate.opsForValue().get(key);

        if (partnerIdStr == null) {
            throw new IllegalArgumentException("Invalid or expired invite code");
        }

        Long partnerId = Long.parseLong(partnerIdStr);
        if (partnerId.equals(userId)) {
            throw new IllegalArgumentException("Cannot couple with yourself");
        }

        User partner = userRepository.findById(partnerId).orElseThrow(() -> new IllegalArgumentException("Partner not found"));
        if (partner.getCoupleId() != null) {
            throw new IllegalStateException("Partner is already in a couple");
        }

        // Create Couple
        Couple couple = new Couple(partnerId, userId);
        couple = coupleRepository.save(couple);

        // Update Users
        me.setCoupleId(couple.getId());
        partner.setCoupleId(couple.getId());

        // Remove code
        redisTemplate.delete(key);

        return couple.getId();
    }
}
