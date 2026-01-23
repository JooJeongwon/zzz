package com.zzz.core.domain.ai;

import com.zzz.core.IntegrationTestSupport;
import com.zzz.core.domain.ai.event.AIEventPublisher;
import com.zzz.core.domain.ai.event.AIRequestEvent;
import com.zzz.core.domain.ai.event.AIResponseEvent;
import com.zzz.core.domain.chat.ChatMessage;
import com.zzz.core.domain.chat.ChatRepository;
import com.zzz.core.global.config.RabbitMqConfig;
import org.junit.jupiter.api.Test;
import org.springframework.amqp.core.AmqpAdmin;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

class AiMessageQueueIntegrationTest extends IntegrationTestSupport {

    @Autowired
    private AIEventPublisher aiEventPublisher;

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private ChatRepository chatRepository;

    @Autowired
    private AmqpAdmin amqpAdmin;

    @Test
    void testPublishChatRequest() {
        // Given
        String testQueueName = "test.ai.request.queue";
        Queue testQueue = new Queue(testQueueName, false);
        amqpAdmin.declareQueue(testQueue);
        TopicExchange aiExchange = new TopicExchange(RabbitMqConfig.AI_EXCHANGE_NAME);
        // Ensure exchange exists (it should be auto-configured, but good for safety)
        amqpAdmin.declareExchange(aiExchange);
        amqpAdmin.declareBinding(BindingBuilder.bind(testQueue).to(aiExchange).with(RabbitMqConfig.AI_REQUEST_CHAT_ROUTING_KEY));

        AIRequestEvent event = AIRequestEvent.builder()
                .requestId("req-123")
                .userId("100")
                .partnerId("200")
                .type("CHAT")
                .content("Hello AI")
                .build();

        // When
        aiEventPublisher.publishChatRequest(event);

        // Then
        Object received = rabbitTemplate.receiveAndConvert(testQueueName, 5000);
        assertThat(received).isNotNull();
        assertThat(received).isInstanceOf(AIRequestEvent.class);
        AIRequestEvent receivedEvent = (AIRequestEvent) received;
        assertThat(receivedEvent.getRequestId()).isEqualTo("req-123");
        assertThat(receivedEvent.getContent()).isEqualTo("Hello AI");
        
        // Cleanup
        amqpAdmin.deleteQueue(testQueueName);
    }

    @Test
    void testHandleAIResponse() {
        // Given
        String requestId = "req-456";
        String content = "This is an AI response";
        AIResponseEvent responseEvent = AIResponseEvent.builder()
                .originalRequestId(requestId)
                .userId("100")     // Receiver (User A)
                .partnerId("200")  // Sender (User B - represented by AI)
                .type("CHAT")
                .content(content)
                .build();

        // When
        rabbitTemplate.convertAndSend(RabbitMqConfig.AI_EXCHANGE_NAME, RabbitMqConfig.AI_RESPONSE_ROUTING_KEY, responseEvent);

        // Then
        await().atMost(10, TimeUnit.SECONDS).untilAsserted(() -> {
            List<ChatMessage> messages = chatRepository.findAll();
            assertThat(messages).isNotEmpty();
            boolean exists = messages.stream().anyMatch(msg -> 
                msg.getContent().equals(content) && 
                msg.isAiGenerated() &&
                msg.getSenderId().equals(200L) &&
                msg.getReceiverId().equals(100L)
            );
            assertThat(exists).isTrue();
        });
    }
}
