package com.zzz.core.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import com.zzz.core.domain.user.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "상대방 상태 조회 응답")
public class PartnerStatusResponse {
    @Schema(description = "유저 ID", example = "1")
    private Long userId;
    @Schema(description = "닉네임", example = "Joo")
    private String nickname;
    @Schema(description = "현재 상태", example = "SLEEP")
    private UserStatus status;
    @Schema(description = "마지막 활동 시간", example = "2024-01-20T10:00:00")
    private LocalDateTime lastActiveAt;
    @Schema(description = "배터리 잔량", example = "85")
    private Integer batteryLevel; // Optional
    @Schema(description = "커플 레벨", example = "5")
    private Integer coupleLevel;
    @Schema(description = "커플 현재 경험치", example = "50")
    private Integer coupleXp;
    @Schema(description = "동기화 시작 시간 (없으면 null)", example = "2024-01-20T12:00:00")
    private LocalDateTime syncStartTime;
    @Schema(description = "룸 꾸미기 타입", example = "STUDY_ROOM")
    private String decorationType;
}
