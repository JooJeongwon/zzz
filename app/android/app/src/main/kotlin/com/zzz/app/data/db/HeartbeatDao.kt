package com.zzz.app.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface HeartbeatDao {
    @Insert
    suspend fun insert(heartbeat: HeartbeatEntity)

    @Query("SELECT * FROM heartbeat_logs ORDER BY timestamp ASC")
    suspend fun getAll(): List<HeartbeatEntity>

    @Query("DELETE FROM heartbeat_logs")
    suspend fun deleteAll()

    @Query("DELETE FROM heartbeat_logs WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)
}
