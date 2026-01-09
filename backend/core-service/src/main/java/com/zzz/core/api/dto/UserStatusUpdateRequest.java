package com.zzz.core.api.dto;

import lombok.Data;

@Data
public class UserStatusUpdateRequest {
    private String status; // ONLINE, SLEEP, STUDY, BUSY
}
