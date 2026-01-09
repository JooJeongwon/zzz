package com.zzz.core.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zzz.core.api.dto.*;
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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class CoupleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("커플 연결 시나리오: User A 초대 -> User B 연결 -> 상태 조회")
    void coupleConnectionScenario() throws Exception {
        // 1. User A 회원가입 & 로그인
        String accessTokenA = registerAndLogin("userA@test.com", "userA", "UserA");

        // 2. User B 회원가입 & 로그인
        String accessTokenB = registerAndLogin("userB@test.com", "userB", "UserB");

        // 3. User A 초대 코드 생성
        MvcResult inviteResult = mockMvc.perform(post("/api/v1/couples/invite")
                        .header("Authorization", "Bearer " + accessTokenA))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").exists())
                .andReturn();
        
        String inviteRespStr = inviteResult.getResponse().getContentAsString();
        CoupleInviteResponse inviteResponse = objectMapper.readValue(inviteRespStr, CoupleInviteResponse.class);
        String inviteCode = inviteResponse.getCode();

        // 4. User B 커플 연결 시도
        CoupleConnectRequest connectRequest = new CoupleConnectRequest();
        connectRequest.setCode(inviteCode);

        mockMvc.perform(post("/api/v1/couples/connect")
                        .header("Authorization", "Bearer " + accessTokenB)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(connectRequest)))
                .andDo(print())
                .andExpect(status().isOk());

        // 5. User A 파트너 상태 조회 (User B 정보가 나와야 함)
        mockMvc.perform(get("/api/v1/couples/partner-status")
                        .header("Authorization", "Bearer " + accessTokenA))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nickname").value("UserB")) // User B nickname
                .andExpect(jsonPath("$.status").exists());
        
        // 6. User B 파트너 상태 조회 (User A 정보가 나와야 함)
        mockMvc.perform(get("/api/v1/couples/partner-status")
                        .header("Authorization", "Bearer " + accessTokenB))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nickname").value("UserA"));
    }

    private String registerAndLogin(String email, String password, String nickname) throws Exception {
        UserRegisterRequest registerRequest = new UserRegisterRequest();
        ReflectionTestUtils.setField(registerRequest, "email", email);
        ReflectionTestUtils.setField(registerRequest, "password", password);
        ReflectionTestUtils.setField(registerRequest, "nickname", nickname);

        mockMvc.perform(post("/api/v1/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isCreated());

        UserLoginRequest loginRequest = new UserLoginRequest();
        loginRequest.setEmail(email);
        loginRequest.setPassword(password);

        MvcResult loginResult = mockMvc.perform(post("/api/v1/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        TokenResponse tokenResponse = objectMapper.readValue(responseBody, TokenResponse.class);
        return tokenResponse.getAccessToken();
    }
}
