package com.zzz.core;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.boot.test.mock.mockito.MockBean;
import com.google.firebase.messaging.FirebaseMessaging;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public abstract class IntegrationTestSupport {

    @MockBean
    protected FirebaseMessaging firebaseMessaging;

    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        // Redis
        registry.add("spring.data.redis.host", () -> "localhost");
        registry.add("spring.data.redis.port", () -> 6379);
        
        // MySQL
        registry.add("spring.datasource.url", () -> "jdbc:mysql://localhost:3306/zzz_core?serverTimezone=UTC&characterEncoding=UTF-8");
        registry.add("spring.datasource.username", () -> "zzz_user");
        registry.add("spring.datasource.password", () -> "zzz_password");
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");
        registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.MySQLDialect");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "update"); 

        // RabbitMQ
        registry.add("spring.rabbitmq.host", () -> "localhost");
        registry.add("spring.rabbitmq.port", () -> 5672);
        registry.add("spring.rabbitmq.username", () -> "guest");
        registry.add("spring.rabbitmq.password", () -> "guest");

        // Mongo
        registry.add("spring.data.mongodb.host", () -> "localhost");
        registry.add("spring.data.mongodb.port", () -> 27017);
        registry.add("spring.data.mongodb.username", () -> "root");
        registry.add("spring.data.mongodb.password", () -> "rootpassword");
        registry.add("spring.data.mongodb.database", () -> "zzz_chat");
        registry.add("spring.data.mongodb.authentication-database", () -> "admin");
    }
}