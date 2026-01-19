package com.zzz.app.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "heartbeat_logs")
data class HeartbeatEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val timestamp: Long,
    val batteryLevel: Int,
    val isScreenOn: Boolean
)
