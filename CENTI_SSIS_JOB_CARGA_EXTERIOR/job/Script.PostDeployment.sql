USE [msdb]
GO

/****** SOLO FUNCIONAL LA ESTRUCTURA ******/

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 2/1/2024 12:34:21 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'JOB_SSIS_CARGA_CENTINELA_COMISIONES_EXT')
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_delete_job @job_name=N'JOB_SSIS_CARGA_CENTINELA_COMISIONES_EXT'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

BEGIN
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'JOB_SSIS_CARGA_CENTINELA_COMISIONES_EXT', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'CArga de datos de Repxt a Bd_Centinela als y tc (cero y mora)', 
        @category_name=N'Data Collector', 
        @owner_login_name=N'$(_v_user_job)', @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [step_exe_carga_centinela]    Script Date: 2/1/2024 12:34:21 PM ******/
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'step_exe_carga_centinela', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1,
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'SSIS', 
        @command=N'/ISSERVER "\"\SSISDB\CENTINELA\SSSIS_CARGA_CENTINELA_COMISION_EXT\CARGA_CENTINELA_COMISIONES_EXT.dtsx\"" /SERVER $(_v_nameServer_job) /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
        @database_name=N'master', 
        @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Carga Centinela', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20240201, 
        @active_end_date=99991231, 
        @active_start_time=80000, 
        @active_end_time=235959, 
        @schedule_uid=N'f37f99bc-4003-475b-932f-679cc929de83'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
