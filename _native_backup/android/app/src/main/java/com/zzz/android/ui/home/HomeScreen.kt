package com.zzz.android.ui.home

import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.zzz.android.data.local.TokenManager
import com.zzz.android.data.remote.dto.PartnerStatusResponse
import com.zzz.android.di.NetworkModule
import com.zzz.android.service.HeartbeatService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun HomeScreen(navController: NavController) {
    val context = LocalContext.current
    val tokenManager = remember { TokenManager(context) }
    val userId by tokenManager.userId.collectAsState(initial = null)
    val scope = rememberCoroutineScope()

    var partnerStatus by remember { mutableStateOf<PartnerStatusResponse?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    // Fetch Partner Status
    fun fetchPartnerStatus() {
        scope.launch {
            isLoading = true
            errorMsg = null
            try {
                val response = withContext(Dispatchers.IO) {
                    NetworkModule.provideCoupleApi(context).getPartnerStatus()
                }
                if (response.isSuccessful) {
                    partnerStatus = response.body()
                } else {
                    // 404 or 400 likely means no couple
                    partnerStatus = null
                    if (response.code() != 404) {
                       errorMsg = "Failed to fetch status: ${response.code()}"
                    }
                }
            } catch (e: Exception) {
                errorMsg = "Network error: ${e.message}"
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(Unit) {
        fetchPartnerStatus()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header
        Text(
            text = "ZZZ Dashboard",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        Text(text = "My User ID: ${userId ?: "..."}", style = MaterialTheme.typography.bodySmall)

        Spacer(modifier = Modifier.height(24.dp))

        // Partner Status Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text("Partner Status", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(16.dp))

                if (isLoading) {
                    CircularProgressIndicator()
                } else if (partnerStatus != null) {
                    val status = partnerStatus!!
                    
                    // Replaced simple StatusIndicator with CharacterView
                    CharacterView(status = status.status)
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = status.nickname,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(text = "Status: ${status.status}", color = MaterialTheme.colorScheme.primary)
                    
                    status.batteryLevel?.let {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(text = "Battery: $it%", style = MaterialTheme.typography.bodyMedium)
                    }
                    
                    status.lastActiveAt?.let {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(text = "Last Active: $it", style = MaterialTheme.typography.labelSmall)
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Button(onClick = { navController.navigate("chat/${status.userId}") }) {
                        Text("Chat with Partner")
                    }
                } else {
                    Text("No partner connected yet.", style = MaterialTheme.typography.bodyMedium)
                    if (errorMsg != null) {
                        Text(errorMsg!!, color = Color.Red, style = MaterialTheme.typography.labelSmall)
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(onClick = { /* Navigate to Couple Connect Screen (TODO) */ }) {
                        Text("Connect Couple")
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(onClick = { fetchPartnerStatus() }) {
            Icon(Icons.Default.Refresh, contentDescription = "Refresh")
            Spacer(modifier = Modifier.width(8.dp))
            Text("Refresh Status")
        }

        Spacer(modifier = Modifier.weight(1f))

        // Service Controls
        Text("My Controls", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Button(onClick = {
                userId?.let { uid ->
                    val intent = Intent(context, HeartbeatService::class.java).apply {
                        putExtra("USER_ID", uid)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                    Toast.makeText(context, "Heartbeat Started", Toast.LENGTH_SHORT).show()
                }
            }, enabled = userId != null) {
                Text("Start Service")
            }
            
            Button(
                onClick = {
                    val intent = Intent(context, HeartbeatService::class.java)
                    context.stopService(intent)
                    Toast.makeText(context, "Heartbeat Stopped", Toast.LENGTH_SHORT).show()
                },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
            ) {
                Text("Stop Service")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedButton(onClick = {
            scope.launch {
                tokenManager.clearToken()
                navController.navigate("login") {
                    popUpTo("home") { inclusive = true }
                }
            }
        }) {
            Text("Logout")
        }
    }
}

// StatusIndicator removed as it is replaced by CharacterView

