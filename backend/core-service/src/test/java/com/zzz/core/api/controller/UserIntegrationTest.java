package com.zzz.core.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zzz.core.api.dto.HeartbeatRequest;
import com.zzz.core.api.dto.UserLoginRequest;
import com.zzz.core.api.dto.UserRegisterRequest;
import com.zzz.core.api.dto.UserStatusUpdateRequest;
import com.zzz.core.api.dto.TokenResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("회원가입 -> 로그인 -> 상태 변경 -> 하트비트 전송 시나리오 테스트")
    void userLifecycleScenario() throws Exception {
        // 1. 회원가입
        String email = "test@example.com";
        String password = "password123";
        String nickname = "tester";

        UserRegisterRequest registerRequest = new UserRegisterRequest();
        ReflectionTestUtils.setField(registerRequest, "email", email);
        ReflectionTestUtils.setField(registerRequest, "password", password);
        ReflectionTestUtils.setField(registerRequest, "nickname", nickname);

        mockMvc.perform(post("/api/v1/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andDo(print())
                .andExpect(status().isCreated());

        // 2. 로그인
        UserLoginRequest loginRequest = new UserLoginRequest();
        loginRequest.setEmail(email);
        loginRequest.setPassword(password);

        MvcResult loginResult = mockMvc.perform(post("/api/v1/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").exists())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        TokenResponse tokenResponse = objectMapper.readValue(responseBody, TokenResponse.class);
        String accessToken = tokenResponse.getAccessToken();

        // 3. 상태 변경 (ONLINE -> STUDY)
        UserStatusUpdateRequest statusRequest = new UserStatusUpdateRequest();
        statusRequest.setStatus("STUDY");

        mockMvc.perform(post("/api/v1/users/status")
                        .header("Authorization", "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusRequest)))
                .andDo(print())
                .andExpect(status().isOk());

        // 4. 하트비트 전송
        HeartbeatRequest heartbeatRequest = HeartbeatRequest.builder()
                .batteryLevel(85)
                .isScreenOn(true)
                .build();

        mockMvc.perform(post("/api/v1/users/heartbeat")
                        .header("Authorization", "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(heartbeatRequest)))
                .andDo(print())
                .andExpect(status().isOk());
    }
}
