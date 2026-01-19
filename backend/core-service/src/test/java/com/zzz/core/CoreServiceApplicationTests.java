package com.zzz.core;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import com.google.firebase.messaging.FirebaseMessaging;

@SpringBootTest
class CoreServiceApplicationTests {

    @MockBean
    private FirebaseMessaging firebaseMessaging;

	@Test
	void contextLoads() {
	}

}