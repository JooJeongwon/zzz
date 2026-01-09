package com.zzz.core.domain.chat.client;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIChatRequest {
    private String user_id;
    private String partner_id;
    private String partner_name;
    private String message;
}
