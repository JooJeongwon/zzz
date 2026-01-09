package com.zzz.core.domain.chat.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "ai-service", url = "${ai-service.url:http://localhost:8000/api/v1}")
public interface AIServiceClient {

    @PostMapping("/chat/generate")
    AIChatResponse generateResponse(@RequestBody AIChatRequest request);

    @PostMapping("/chat/recap")
    AIChatResponse generateRecap(@RequestBody AIChatRequest request);
}
