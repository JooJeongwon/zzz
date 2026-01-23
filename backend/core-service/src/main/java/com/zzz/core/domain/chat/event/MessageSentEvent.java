package com.zzz.core.domain.chat.event;

import com.zzz.core.domain.user.UserStatus;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MessageSentEvent {
    private final Long senderId;
    private final Long receiverId;
    private final String content;
    private final UserStatus receiverStatus;
    private final String receiverNickname;
}
