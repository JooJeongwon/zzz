package com.zzz.core.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

@Configuration
public class FirebaseConfig {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${fcm.config-path}")
    private String fcmConfigPath;

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        try {
            FirebaseApp firebaseApp = null;
            List<FirebaseApp> apps = FirebaseApp.getApps();
            
            if (apps != null && !apps.isEmpty()) {
                for (FirebaseApp app : apps) {
                    if (app.getName().equals(FirebaseApp.DEFAULT_APP_NAME)) {
                        firebaseApp = app;
                        break;
                    }
                }
            }

            if (firebaseApp == null) {
                InputStream serviceAccount = null;
                try {
                    // Try loading from classpath first
                    serviceAccount = new ClassPathResource(fcmConfigPath).getInputStream();
                } catch (Exception e) {
                    // Fallback to file system
                    try {
                        serviceAccount = new FileInputStream(fcmConfigPath);
                    } catch (Exception ex) {
                         logger.warn("FCM config file not found at {}. Push notifications will be disabled.", fcmConfigPath);
                         return null;
                    }
                }

                if (serviceAccount != null) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    firebaseApp = FirebaseApp.initializeApp(options);
                    logger.info("Firebase Application has been initialized");
                }
            }
            
            if (firebaseApp != null) {
                return FirebaseMessaging.getInstance(firebaseApp);
            }

        } catch (IOException e) {
            logger.error("Failed to initialize Firebase", e);
        }

        return null;
    }
}
