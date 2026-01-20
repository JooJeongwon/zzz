package com.zzz.core;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import static org.assertj.core.api.Assertions.assertThat;

class IntegrationEnvironmentTest extends IntegrationTestSupport {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    void contextLoads() {
        // Just loading the context verifies containers are up and app can connect
    }

    @Test
    void testMysqlConnection() {
        String result = jdbcTemplate.queryForObject("SELECT VERSION()", String.class);
        assertThat(result).isNotNull();
        System.out.println("MySQL Version: " + result);
    }

    @Test
    void testRedisConnection() {
        redisTemplate.opsForValue().set("test-key", "test-value");
        Object value = redisTemplate.opsForValue().get("test-key");
        assertThat(value).isEqualTo("test-value");
    }

    @Test
    void testRabbitMqConnection() {
        assertThat(rabbitTemplate.getConnectionFactory()).isNotNull();
        // Simple check to see if we can access the connection factory
        System.out.println("RabbitMQ Host: " + rabbitTemplate.getConnectionFactory().getHost());
    }
}
