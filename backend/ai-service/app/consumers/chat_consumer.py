import json
import logging
import asyncio
import functools
import aio_pika
from app.core.rabbitmq import rabbitmq_client
from app.services.rag_service import rag_service
from app.services.llm_service import get_llm_service

logger = logging.getLogger(__name__)

async def run_blocking(func, *args, **kwargs):
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, functools.partial(func, *args, **kwargs))

async def process_chat_request(message: aio_pika.IncomingMessage):
    async with message.process():
        try:
            body = json.loads(message.body)
            logger.info(f"Received chat request: {body}")
            
            request_id = body.get("requestId")
            user_id = body.get("userId")
            partner_id = body.get("partnerId")
            partner_name = body.get("partnerName")
            content = body.get("content")
            
            response_text = await run_blocking(
                rag_service.get_persona_response,
                target_persona_id=partner_id,
                message=content,
                partner_name=partner_name
            )
            
            response_payload = {
                "originalRequestId": request_id,
                "userId": user_id,
                "partnerId": partner_id,
                "partnerName": partner_name,
                "content": response_text,
                "type": "CHAT"
            }
            
            await publish_response(response_payload)
            
        except Exception as e:
            logger.error(f"Error processing chat request: {e}")

async def process_recap_request(message: aio_pika.IncomingMessage):
    async with message.process():
        try:
            body = json.loads(message.body)
            logger.info(f"Received recap request: {body}")
            
            request_id = body.get("requestId")
            user_id = body.get("userId")
            partner_id = body.get("partnerId")
            content = body.get("content")
            
            response_text = await run_blocking(
                get_llm_service().generate_recap,
                conversation_history=content,
                user_name="User"
            )
            
            response_payload = {
                "originalRequestId": request_id,
                "userId": user_id,
                "partnerId": partner_id,
                "content": response_text,
                "type": "RECAP"
            }
            
            await publish_response(response_payload)
            
        except Exception as e:
            logger.error(f"Error processing recap request: {e}")

async def process_dream_log_request(message: aio_pika.IncomingMessage):
    async with message.process():
        try:
            body = json.loads(message.body)
            logger.info(f"Received dream log request: {body}")
            
            request_id = body.get("requestId")
            user_id = body.get("userId")
            partner_id = body.get("partnerId")
            content = body.get("content")
            
            response_text = await run_blocking(
                rag_service.generate_dream_log,
                chat_history=content
            )
            
            response_payload = {
                "originalRequestId": request_id,
                "userId": user_id,
                "partnerId": partner_id,
                "content": response_text,
                "type": "DREAM_LOG"
            }
            
            await publish_response(response_payload)
            
        except Exception as e:
            logger.error(f"Error processing dream log request: {e}")

async def publish_response(payload: dict):
    channel = await rabbitmq_client.get_channel()
    exchange = await channel.get_exchange("ai.exchange", ensure=False) # Assumes exchange exists
    
    await exchange.publish(
        aio_pika.Message(body=json.dumps(payload).encode()),
        routing_key="ai.response"
    )
    logger.info(f"Published AI response: {payload}")

async def start_consumers():
    channel = await rabbitmq_client.get_channel()
    
    # Declare Exchange (Idempotent)
    exchange = await channel.declare_exchange("ai.exchange", aio_pika.ExchangeType.TOPIC, durable=True)
    
    # Chat Queue
    chat_queue = await channel.declare_queue("queue.ai.chat", durable=True)
    await chat_queue.bind(exchange, routing_key="ai.request.chat")
    await chat_queue.consume(process_chat_request)
    
    # Recap Queue
    recap_queue = await channel.declare_queue("queue.ai.recap", durable=True)
    await recap_queue.bind(exchange, routing_key="ai.request.recap")
    await recap_queue.consume(process_recap_request)

    # Dream Log Queue
    dream_queue = await channel.declare_queue("queue.ai.dream", durable=True)
    await dream_queue.bind(exchange, routing_key="ai.request.dream")
    await dream_queue.consume(process_dream_log_request)
    
    logger.info("AI Service consumers started")