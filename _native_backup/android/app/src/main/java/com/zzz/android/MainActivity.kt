package com.zzz.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.zzz.android.data.local.TokenManager
import com.zzz.android.ui.auth.LoginScreen
import com.zzz.android.ui.auth.RegisterScreen
import com.zzz.android.ui.home.HomeScreen
import com.zzz.android.ui.chat.ChatScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    AppNavigation()
                }
            }
        }
    }
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val context = LocalContext.current
    val tokenManager = TokenManager(context)
    val accessToken by tokenManager.accessToken.collectAsState(initial = null)
    
    // Simple logic: if token exists, start at home, else login.
    // Note: In a real app, you might want a splash screen to check this state to avoid flicker.
    // For now, we default to login if null, but if we had a token, we'd want to navigate.
    // Since 'initial' is null, it might flicker to login first. 
    
    // A better approach for this prototype:
    val startDestination = if (accessToken != null) "home" else "login"

    NavHost(navController = navController, startDestination = "login") {
        composable("login") { 
            // If we are here but actually have a token (re-composition), navigate home
            if (accessToken != null) {
                // Side-effect to navigate? Or just let the user see login briefly?
                // For simplicity, let's keep it manual or handle in the screen.
                // But normally we'd determine startDestination based on a Splash screen logic.
            }
            LoginScreen(navController) 
        }
        composable("register") { RegisterScreen(navController) }
        composable("home") { HomeScreen(navController) }
        composable(
            "chat/{partnerId}",
            arguments = listOf(navArgument("partnerId") { type = NavType.LongType })
        ) { backStackEntry ->
            val partnerId = backStackEntry.arguments?.getLong("partnerId") ?: 0L
            ChatScreen(navController, partnerId)
        }
    }
}