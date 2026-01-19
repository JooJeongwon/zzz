import aio_pika
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class RabbitMQClient:
    def __init__(self):
        self.connection = None
        self.channel = None

    async def connect(self):
        try:
            self.connection = await aio_pika.connect_robust(settings.RABBITMQ_URL)
            self.channel = await self.connection.channel()
            logger.info("Connected to RabbitMQ")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise e

    async def close(self):
        if self.connection:
            await self.connection.close()
            logger.info("Closed RabbitMQ connection")

    async def get_channel(self):
        if not self.channel or self.channel.is_closed:
            if not self.connection or self.connection.is_closed:
                await self.connect()
            self.channel = await self.connection.channel()
        return self.channel

rabbitmq_client = RabbitMQClient()
