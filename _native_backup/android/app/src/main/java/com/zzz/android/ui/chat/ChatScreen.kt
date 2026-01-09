package com.zzz.android.ui.chat

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.zzz.android.data.local.TokenManager
import com.zzz.android.data.remote.dto.ChatMessageDto
import com.zzz.android.data.remote.dto.SendMessageRequest
import com.zzz.android.di.NetworkModule
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(navController: NavController, partnerId: Long) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val tokenManager = remember { TokenManager(context) }
    val userId by tokenManager.userId.collectAsState(initial = null)

    var messages by remember { mutableStateOf<List<ChatMessageDto>>(emptyList()) }
    var inputText by remember { mutableStateOf(TextFieldValue("")) }
    var isLoading by remember { mutableStateOf(false) }

    val chatApi = NetworkModule.provideChatApi(context)

    fun fetchMessages() {
        scope.launch {
            try {
                val response = chatApi.getChatHistory(partnerId = partnerId, page = 0, size = 50)
                if (response.isSuccessful) {
                    // Backend returns newest first because of OrderByCreatedAtDesc?
                    // Usually chat UI expects oldest at top if not reversed, or newest at bottom.
                    // If backend is Descending (Newest first), we should reverse it for display if we stack from top,
                    // or use reverseLayout=true in LazyColumn and keep it as is.
                    // Let's assume standard LazyColumn (top->bottom) needs oldest->newest.
                    messages = response.body()?.content?.reversed() ?: emptyList()
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    fun sendMessage() {
        if (inputText.text.isBlank()) return
        val text = inputText.text
        inputText = TextFieldValue("") // Clear input immediately

        scope.launch {
            try {
                val request = SendMessageRequest(receiverId = partnerId, content = text)
                val response = chatApi.sendMessage(request)
                if (response.isSuccessful) {
                    // Optimistic update or refresh
                    fetchMessages()
                } else {
                    Toast.makeText(context, "Failed to send", Toast.LENGTH_SHORT).show()
                    inputText = TextFieldValue(text) // Restore text on fail
                }
            } catch (e: Exception) {
                Toast.makeText(context, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                inputText = TextFieldValue(text)
            }
        }
    }

    // Polling for new messages
    LaunchedEffect(Unit) {
        while (true) {
            fetchMessages()
            delay(3000) // Poll every 3 seconds
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Chat with Partner") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(8.dp),
                verticalArrangement = Arrangement.Bottom // Stick to bottom? No, standard is top-down filled.
            ) {
                items(messages) { msg ->
                    val isMe = msg.senderId == userId
                    MessageBubble(message = msg, isMe = isMe)
                    Spacer(modifier = Modifier.height(4.dp))
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = inputText,
                    onValueChange = { inputText = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Type a message...") }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(onClick = { sendMessage() }) {
                    Icon(Icons.Default.Send, contentDescription = "Send")
                }
            }
        }
    }
}

@Composable
fun MessageBubble(message: ChatMessageDto, isMe: Boolean) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = if (isMe) Alignment.End else Alignment.Start
    ) {
        Surface(
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isMe) 16.dp else 0.dp,
                bottomEnd = if (isMe) 0.dp else 16.dp
            ),
            color = if (isMe) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Text(
                text = message.content,
                modifier = Modifier.padding(12.dp),
                color = if (isMe) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        if (message.isAiGenerated) {
            Text(
                text = "AI",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.secondary,
                modifier = Modifier.padding(start = 4.dp, end = 4.dp)
            )
        }
    }
}
