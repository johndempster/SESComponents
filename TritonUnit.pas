unit TritonUnit;
// ------------------------------------
// Tecella Triton 16 channel patch clamp
// ------------------------------------
// (c) J. Dempster, University of Strathclyde, 2008-10
// 9.07.08
// 04.09.08 Revised to work with TecellaAmp.dll library
// 22.07.09 Updated to work with V0.111 library
//          tecella_chan_set does not seem to be working correctly 24/7/9
// 24.03.10 Updated to work with V0.119 library
// 01.06.10 Sampling interval constrained to be a multiple of hwprops.sample_period_min
//          rather than hwprops.sample_period_lsb to ensure synthesized
//          voltage pulse is same duration as recorded current
//          Channel gain setting now returned in Triton_Gain
//          as multiple of minimum gain.
// 29.07.10 Support for Pico added
// 26.08.01 Support for PICO still under development
// 08.09.10 Triton_Zap function added
// 06.01.11 Triton_Calibrate & Triton_IsCalibrated and now saves calibration data in file V0.119.50 API.
//          FDACMaxVolts initialised to 1.0 to avoid FP errors when
//          Tecella selected as amplifier but not as interface
// 19.05.11 Voltage ramps now supported for V(+/-255mV) mode.
//          No. of samples/record can be varied 256-32768
//          Sampling interval adjusted upwards by 1 tick to ensure records are no more than 5% smaller than requested
// 07.06.11 Digital leak subtraction and arterfact subtraction added to compensation.
// 16.06.11 TritonGetUserConfig now returns config # correctly
// 23.08.11 I=0 config name excluded from calibration. Tested with Pico2
// 28.10.11 DAC stream output now used with Pico.
// 31.10.11 Triton_GetMaxDACVolts now returns upper limit of DAC range
//          for selected channel (0=stimulus, 1=DAC 1)
// 02.11.11 Utility DAC and digital outputs now supported Free run trigger mode supported.
// 23.12.11 DAC streaming can now be disabled for Tecella PICO
// 17.01.12 Triton_MemoryToDACAndDigitalOutStream: DAC stimulus stream values divided by 10
//          in current clamp mode to keep signal scaling correct I(Not sure why this is
//          necessary
// 14.03.12 Upgraded to TecellaAmp V0.84. I=0 mode removed from config list and replaced with
//          ICLAMPOn mode setting which enabled/disables current commands. When IClampOn=False
//          clamp acts as voltage follower.
// 10.04.12 CFast & CSlowA-D can now be enabled/disabled for auto compensation

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem, math, classes, strutils ;

const

  TECELLA_CalibrationFileName = 'tecella Calibration.cal' ;
  SamplingMultiplierMax = 10000 ;

	TECELLA_HW_MODEL_AUTO_DETECT = 0 ;
	TECELLA_HW_MODEL_TRITON = 1 ;
	TECELLA_HW_MODEL_TRITON_PLUS = 2 ;
	TECELLA_HW_MODEL_JET = 3 ;
	TECELLA_HW_MODEL_RICHMOND = 4 ;
	TECELLA_HW_MODEL_PROTEUS = 5 ;
	TECELLA_HW_MODEL_APOLLO = 6 ;
	TECELLA_HW_MODEL_WALL_E = 7 ;
	TECELLA_HW_MODEL_SHASTA = 8 ;
  TECELLA_HW_MODEL_PICO = 9 ;

    TECELLA_REG_CFAST = 0 ;
    TECELLA_REG_CSLOW_A = 1 ;
    TECELLA_REG_CSLOW_B = 2 ;
    TECELLA_REG_CSLOW_C = 3 ;
    TECELLA_REG_CSLOW_D = 4 ;
    TECELLA_REG_RSERIES = 5 ;
    TECELLA_REG_LEAK = 6 ;
    TECELLA_REG_JP = 7 ;
    TECELLA_REG_JP_FINE = 8 ;
  	TECELLA_REG_LEAK_FINE = 9 ;
	  TECELLA_REG_ICMD_OFFSET = $A ;

  	TECELLA_OAM_OFF = 0 ;
	  TECELLA_OAM_ADJUST_STIMULUS = 1 ;  //**< Adjusts JP.  JP must be supported by the hardware. */
	  TECELLA_OAM_ADJUST_RESPONSE = 2 ;  //**< Adjusts the response offset. */
	  TECELLA_OAM_ADJUST_STIMULUS_AND_RESPONSE = 3 ; //**< Adjusts both JP and the response offset. */



  TECELLA_STIMULUS_MODE_VCMD = 0 ; // **< A voltage stimulus is applied and the current response is acquired. */
	TECELLA_STIMULUS_MODE_ICMD = 1 ; //< A current stimulus is applied and voltage response is acquired. */
	TECELLA_STIMULUS_MODE_OSCOPE = 2 ;

  TECELLA_STIMULUS_SEGMENT_SET = 0 ; 		    //**< A flat segment. */
	TECELLA_STIMULUS_SEGMENT_DELTA = 1 ;    //**< A flat segment that changes its amplitude and/or duration after each iteration. */
	TECELLA_STIMULUS_SEGMENT_RAMP = 2 ;

	//General errors
  TECELLA_ERR_OK = $000 ;
  TECELLA_ERR_NOT_IMPLEMENTED = $001 ;
  TECELLA_ERR_NOT_SUPPORTED = $002 ;
  TECELLA_ERR_BAD_HANDLE = $003 ;
  TECELLA_ERR_INVALID_CHANNEL = $004 ;
  TECELLA_ERR_INVALID_STIMULUS = $005 ;
  TECELLA_ERR_INVALID_CHOICE = $006 ;
  TECELLA_ERR_ALLCHAN_NOT_ALLOWED = $007 ;
  TECELLA_ERR_RETURN_POINTER_NULL = $008 ;
  TECELLA_ERR_ARGUMENT_POINTER_NULL = $009 ;
  TECELLA_ERR_VALUE_OUTSIDE_OF_RANGE = $00A ;
  TECELLA_ERR_INVALID_REGISTER_COMBINATION = $00B ;
  TECELLA_ERR_DEVICE_CONTENTION = $00C ;
  TECELLA_ERR_INTERNAL = $00D ;
  TECELLA_ERR_OKLIB_NOT_FOUND = $100 ;
  TECELLA_ERR_DEVICE_OPEN_FAILED = $101 ;
  TECELLA_ERR_DEVICE_INIT_FAILED = $102 ;
  TECELLA_ERR_INVALID_DEVICE_INDEX = $103 ;
  TECELLA_ERR_STIMULUS_INVALID_SEGMENT_COUNT = $200 ;
  TECELLA_ERR_STIMULUS_INVALID_DURATION = $201 ;
  TECELLA_ERR_STIMULUS_INVALID_VALUE = $202 ;
  TECELLA_ERR_STIMULUS_INVALID_DURATION_DELTA = $203 ;
  TECELLA_ERR_STIMULUS_INVALID_VALUE_DELTA = $204 ;
  TECELLA_ERR_STIMULUS_INVALID_RAMP_STEP_COUNT = $205 ;
  TECELLA_ERR_STIMULUS_INVALID_RAMP_END_VALUE = $206 ;
  TECELLA_ERR_STIMULUS_INVALID_DELTA_COUNT = $207 ;
  TECELLA_ERR_STIMULUS_INVALID_REPEAT_COUNT = $208 ;
  TECELLA_ERR_STIMULUS_INVALID_SEGMENT_SEQUENCE = $209 ;
  TECELLA_ERR_INVALID_SAMPLE_PERIOD = $300 ;
  TECELLA_ERR_HW_BUFFER_OVERFLOW = $301 ;
  TECELLA_ERR_SW_BUFFER_OVERFLOW = $302 ;
  TECELLA_ERR_ACQ_CRC_FAILED = $303 ;
  TECELLA_ERR_CHANNEL_BUFFER_OVERFLOW = $304 ;

    TECELLA_GAIN_NONE = 0 ;
    TECELLA_GAIN_LOW = 1 ;
    TECELLA_GAIN_MID = 2 ;
    TECELLA_GAIN_HI = 3 ;
    TECELLA_GAIN_VHI = 4 ;

    TECELLA_GAIN_A =       0 ;
    TECELLA_GAIN_B =       1 ;
    TECELLA_GAIN_C =       2 ;
    TECELLA_GAIN_D =       3 ;

    TECELLA_SOURCE_NONE = 0 ;
    TECELLA_SOURCE_HEAD = 1 ;
    TECELLA_SOURCE_MODEL1 = 2 ;
    TECELLA_SOURCE_MODEL2 = 3 ;

    TECELLA_HW_PROPS_DEVICE_NAME_SIZE =  32 ;
    TECELLA_HW_PROPS_SERIAL_NUMBER_SIZE =  32 ;
    TECELLA_HW_PROPS_USER_CONFIG_NAME_SIZE =  32 ;
    TECELLA_REG_PROPS_LABEL_SIZE =  32 ;
    TECELLA_REG_PROPS_UNITS_SIZE =  32 ;
    TECELLA_SYSTEM_MONITOR_RESULT_LABEL_SIZE =  32 ;
    TECELLA_SYSTEM_MONITOR_UNITS_LABEL_SIZE = 32 ;
    TECELLA_HW_PROPS_ACQUISITION_UNITS_SIZE = 32 ;
    TECELLA_HW_PROPS_STIMULUS_UNITS_SIZE = 32 ;
    TECELLA_ALLCHAN = $8000 ;
    TECELLA_HW_PROPS_GAIN_NAME_SIZE = 32 ;

type

Ttecella_stimulus_segment = record
	SegmentType : Integer ; //**< Type of segment.  Assumed to be SET, until DELTA and RAMP is supported. */
  Value : Double ;        //**< Amplitude of segment in Volts (if vcmd) or Amps (if icmd). */
	Value_delta : Double ;  //**< If type is TECELLA_STIMULUS_SEGMENT_DELTA, increment value by this delta after each iteration of the vcmd.  If type is TECELLA_STIMULUS_SEGMENT_RAMP, value_delta is used as the value to ramp to by the end of duration. */
  Duration : Double ;     //**< Duration of segment in seconds. */
	Duration_delta : Double ;  //**< Increment duration by this delta after each iteration of the vcmd. Valid only if type is TECELLA_STIMULUS_SEGMENT_DELTA. */
  Ramp_Steps : Integer ;
  end ;

Ttecella_stimulus_segment_ex = record
	SegmentType : Integer ; //**< Type of segment.  Assumed to be SET, until DELTA and RAMP is supported. */
  Value : Double ;        //**< Amplitude of segment in Volts (if vcmd) or Amps (if icmd). */
	Value_delta : Double ;  //**< If type is TECELLA_STIMULUS_SEGMENT_DELTA, increment value by this delta after each iteration of the vcmd.  If type is TECELLA_STIMULUS_SEGMENT_RAMP, value_delta is used as the value to ramp to by the end of duration. */
  Duration : Double ;     //**< Duration of segment in seconds. */
	Duration_delta : Double ;  //**< Increment duration by this delta after each iteration of the vcmd. Valid only if type is TECELLA_STIMULUS_SEGMENT_DELTA. */
  Ramp_Steps : Integer ;
	ramp_step_size : Integer ;  //**< The size of each ramp step. The range is usually limited to [0,4], but check the hwprops to make sure. */
	digital_out : Integer ;     //**< A mask for the digital out bits associated with this stimulus. */
	slew : Integer ;        //**< Select which slew to use right before this segment is applied. */
  end ;

Ttecella_lib_props = packed record
    v_maj : Integer ;
    v_min : Integer ;
    v_dot : Integer ;
    Description : Array[0..255] of WideChar ;
    end ;

Ttecella_hw_props = record
	hw_model : Integer ;
	device_name : Array[0..TECELLA_HW_PROPS_DEVICE_NAME_SIZE-1] of WideChar ;		//**< Name of the device. */
	serial_number : Array[0..TECELLA_HW_PROPS_SERIAL_NUMBER_SIZE-1] of WideChar ;	//**< The serial number, which is unique to each unit. */
	hwvers : Integer ;					//**< Contains the firmware version being used. */
	nchans : Integer ;					//**< Number of channels.  Note: Channel numbering goes from [0, nchans-1]. */
  nslots : Integer ;
	nsources : Integer ;				//**< Number of sources selectable (see TECELLA_REG_SOURCE) */
	ngains : Integer ;					//**< Number of gains selectable (see TECELLA_REG_GAIN) */
	ncslows : Integer ;         //**< Number of cslows slectable */
	n_utility_dacs : Integer ;  //**< Number of utility DACs available. (limits the max index passed to tecella_utility_dac functions.) */
	nstimuli : Integer ;				//**< Number of simultaneous stimuli supported (see TECELLA_REG_stimulus_SELECT) */
	max_stimulus_segments : Integer ;  //**< Maximum number of segments supported per stimulus. */
	supports_async_stimulus : ByteBool ; //**< If true, tecella_acquire_start_stimulus() can be used. */
	supports_oscope : ByteBool ; //**< Indicates if the amplifier can be used as an oscilloscope. */
	supports_vcmd : ByteBool ;      //**< Indicates if the amplifier can produce a voltage stimulus. (See TECELLA_STIMULUS_MODE_VCMD) */
	stimulus_value_min : Double ;	      //**< Minimum voltage value supported by a vcmd stimulus. */
	stimulus_value_max : Double ;	      //**< Maximum voltage value supported by a vcmd stimulus. */
	stimulus_value_lsb : Double ;	      //**< The vcmd stimulus can only take on voltage values in intervals of stimulus_value_lsb from stimulus_value_min to stimulus_value_max. */
  stimulus_ramp_step_size : Double ;  //**< Each step of a ramp vcmd segment will have it's value increased by this amount. */
	supports_icmd : ByteBool ;	    //**< Indicates if the amplifier can produce a current stimulus. (See TECELLA_STIMULUS_MODE_ICMD) */
	reserved_0 : Double ;	      //**< Minimum amp value supported by a icmd stimulus. */
	reserved_1 : Double ;	      //**< Maximum amp value supported by a icmd stimulus. */
	reserved_2 : Double ;	      //**< The icmd stimulus can only take on current values in intervals of stimulus_value_lsb from stimulus_value_min to stimulus_value_max. */
	reserved_3 : Double ;  //**< Each step of a ramp icmd segment will have it's value increased by this amount. */
	stimulus_segment_duration_max : Double ;	//**< The maximum duration a segment can have. */
	stimulus_segment_duration_lsb : Double ;	//**< Duration can only take on values in intervals of stimulus_segment_duration_lsb. */
	stimulus_delta_count_max : Integer ;      //**< The maximum number of delta iterations a stimulus may have. */
	stimulus_repeat_count_max : Integer ;     //**< The maximum number of repeat iterations a stimulus may have. */
	stimulus_ramp_steps_max : Integer ;       //**< The maximum number of ramp steps supported by a single stimulus segment. */
	supports_zap : ByteBool ; //**< Indicates if the amplifier supports tecella_stimulus_zap(). */
	zap_value_min : Double ;	//**< Minimum zap value supported by tecella_stimulus_zap(). */
	zap_value_max : Double ;	//**< Maximum zap value supported by tecella_stimulus_zap(). */
	zap_value_lsb : Double ;	//**< The zap stimulus can only take on voltage values in intervals of zap_value_lsb from zap_value_min to zap_value_max. */
	supports_bessel : ByteBool ; //**< Indicates if a bessel filter is supported */
	bessel_value_min : Integer ;  //**< Minimum programmable bessel value. */
	bessel_value_max : Integer ;  //**< Maximum programmable bessel value. */
	utility_dac_min : Double ;    //**< Utility DAC min in Volts. */
	utility_dac_max : Double ;    //**< Utility DAC max in Volts. */
	utility_dac_lsb : Double ;    //**< Utility DAC lsb in Volts. */
	sample_period_min : Double ;	//**< Minimum sample period supported in seconds. */
	sample_period_max : Double ;	//**< Maximum sample period supported in seconds. */
	sample_period_lsb : Double ;	//**< The sample period can only take on values in intervals of sample_period_lsb from sample_period_min to sample_period_max */
  bits_per_sample : Integer ;   //**< The number of bits per sample. */
  user_config_count : Integer ;
  user_config_name : Array[0..TECELLA_HW_PROPS_USER_CONFIG_NAME_SIZE-1] of WideChar ;
  end ;
Ptecella_hw_props = ^Ttecella_hw_props ;

Ttecella_hw_props_ex_01 = record
	acquisition_units : Array[0..TECELLA_HW_PROPS_ACQUISITION_UNITS_SIZE-1] of WideChar ;
	stimulus_units : Array[0..TECELLA_HW_PROPS_STIMULUS_UNITS_SIZE-1] of WideChar ;
	slew_count : Integer ;
	stimulus_ramp_step_size_min : double ;  //**< The value_delta field can take can be down to this value in stimulus_value_lsb increments. */
	stimulus_ramp_step_size_max : double ;  //**< The value_delta field can take can be up to this value in stimulus_value_lsb increments. */
	supports_hpf : ByteBool ;
	hpf_value_min : Integer ;
	hpf_value_max : Integer ;
  supports_chan_set_stimulus : ByteBool ; //** Some systems with multiple stimuli can map any channel to any stimulus via tecella_chan_set_stimulus(). */
	supports_stimulus_steering : ByteBool ;			//** used on Amadeus. */
	stimulus_steering_index_min : Integer ;
	stimulus_steering_index_max : Integer ;
	stimulus_steering_can_be_disabled : ByteBool ;
	dynamic_system_monitor_count : Integer ; // ndicates how many points the dynamic system monitor can probe. See tecella_system_monitor_dynamic_set().*/
	trigger_in_delay_min : double ;
	trigger_in_delay_max : double ;
	trigger_in_delay_lsb : double ;
	supports_iclamp_enable : ByteBool ; //** Indicates if the iclamp can be enabled and dissabled via tecella_chan_set_iclamp_enable(). *
	supports_vcmd_enable : ByteBool ;   //**< Indicates if the vcmd can be enabled and dissabled via tecella_chan_set_vcmd_enable(). */
	supports_telegraphs : ByteBool ;
	ngains1 : Integer ;
	gain1_name : Array[0..TECELLA_HW_PROPS_GAIN_NAME_SIZE-1] of WideChar ;
	ngains2 : Integer ;
	gain2_name : Array[0..TECELLA_HW_PROPS_GAIN_NAME_SIZE-1] of WideChar ;
  end ;


Ttecella_reg_props = record
  rlabel : Array[0..TECELLA_HW_PROPS_USER_CONFIG_NAME_SIZE-1] of WideChar ;
  units : Array[0..TECELLA_REG_PROPS_UNITS_SIZE-1] of WideChar ;
  supported : ByteBool ;
  can_be_disabled : ByteBool ;
  v_min : Double ;
  v_max : Double ;
  v_lsb : Double ;
  v_divisions : Integer ;
  v_default : Double ;
  pct_lsb : Double ;
  end ;

Ttecella_system_monitor_result = record
  Lab : array[0..TECELLA_SYSTEM_MONITOR_RESULT_LABEL_SIZE-1] of WideChar ;
  units : array[0..TECELLA_SYSTEM_MONITOR_UNITS_LABEL_SIZE-1] of WideChar ;
  board_index : Integer ;
  board_result_index : Integer ;
  value : Double ;
  value_expected : Double ;
  value_expected_min : Double ;
  value_expected_max : Double ;
  end ;

Ttecella_enumerate = function(
                     var NumDevices : Integer ) : Integer ; cdecl ;

Ttecella_enumerate_get = function(
                         DeviceNum : Integer ;
                         pHWProps : Pointer ) : Integer ; cdecl ;

Ttecella_initialize = function(
                    pHandle : Pointer ;
                    HWModel : Integer ) : Integer ; cdecl ;

Ttecella_initialize_pair = function(
                    pHandle : Pointer ;
                    Handle1 : Integer ;
                    Handle2 : Integer ) : Integer ; cdecl ;

Ttecella_finalize = function(
                    Handle : Integer ) : Integer ; cdecl ;

Ttecella_set_stimulus_mode = function(
                             Handle : Integer ;
                             Mode : Integer ) : Integer ; cdecl ;

Ttecella_get_stimulus_mode = function(
                             Handle : Integer ;
                             var Mode : Integer ) : Integer ; cdecl ;

Ttecella_get_lib_props = function(
                         var Props : Ttecella_lib_PROPS ) : Integer ; cdecl ;

Ttecella_get_hw_props = function(
                            Handle : Integer ;
                            var hwprops : TTECELLA_HW_PROPS ) : Integer ; cdecl ;

Ttecella_get_hw_props_ex_01 = function(
                              Handle : Integer ;
                              var hwprops : TTECELLA_HW_PROPS_EX_01 ) : Integer ; cdecl ;

Ttecella_get_reg_props = function(
                         Handle : Integer ;
                         Reg : Integer ;
                         var RegProps : TTECELLA_reg_PROPS ) : Integer ; cdecl ;

Ttecella_get_gain_label = function(
                          Handle : Integer ;
                          gain_index : Integer ;
                          var GainLabel : PWideChar ) : Integer ; cdecl ;

Ttecella_get_source_label = function(
                          Handle : Integer ;
                          gain_index : Integer ;
                          pSourceLabel : Pointer ) : Integer ; cdecl ;


Ttecella_error_get_last_msg = function(
                              Handle : Integer ;
                              Msg : PChar) : Integer ; cdecl ;
Ttecella_error_set_callback  = function(
                               Handle : Integer ;
                               var f : Pointer ) : Integer ; cdecl ;

Ttecella_error_message = function(
                         ErrNum : Integer
                         ) : PWideChar ;

//* Manipulate registers */
Ttecella_chan_set = function(
                   Handle : Integer ;
                   Reg : Integer ;
                   chan : Integer ;
                   value : Double ) : Integer ; cdecl ;
Ttecella_chan_get = function(
                   Handle : Integer ;
                   Reg : Integer ;
                   chan : Integer ;
                   var value : Double
                   ) : Integer ; cdecl ;
Ttecella_chan_set_pct = function(
                       Handle : Integer ;
                       Reg : Integer ;
                       chan : Integer ;
                       pct : Double) : Integer ; cdecl ;

Ttecella_chan_get_pct = function(
                       Handle : Integer ;
                       Reg : Integer ;
                       chan : Integer ;
                       var pct : Double) : Integer ; cdecl ;

Ttecella_chan_to_string = function(
                         Handle : Integer ;
                         Reg : Integer ;
                         chan : Integer ;
                         s : PChar ) : Integer ; cdecl ;
Ttecella_chan_get_units = function(
                         Handle : Integer ;
                         Reg : Integer ;
                         s : PChar ) : Integer ; cdecl ;
Ttecella_chan_set_enable = function(
                          Handle : Integer ;
                          Reg : Integer ;
                          chan : Integer ;
                          Enabled : ByteBool ) : Integer ; cdecl ;
Ttecella_chan_get_enable = function(
                          Handle : Integer ;
                          Reg : Integer ;
                          chan : Integer ;
                          var Enabled : ByteBool ) : Integer ; cdecl ;
Ttecella_chan_set_gain = function(
                        Handle : Integer ;
                        chan : Integer ;
                        Gain : Integer) : Integer ; cdecl ;
Ttecella_chan_get_gain = function(
                        Handle : Integer ;
                        chan : Integer ;
                        var Gain : Integer ) : Integer ; cdecl ;
Ttecella_chan_set_source = function(
                          Handle : Integer ;
                          chan : Integer ;
                          src : Integer ) : Integer ; cdecl ;
Ttecella_chan_get_source = function(
                          Handle : Integer ;
                          chan : Integer ;
                          var src : Integer ) : Integer ; cdecl ;
Ttecella_chan_set_bessel = function(
                        Handle : Integer ;
                        chan : Integer ;
                        Value : Integer) : Integer ; cdecl ;
Ttecella_chan_get_bessel = function(
                        Handle : Integer ;
                        chan : Integer ;
                        var Value : Integer ) : Integer ; cdecl ;

Ttecella_bessel_value2freq = function(
                        Handle : Integer ;
                        Value : Integer ;
                        var Freq : double ) : Integer ; cdecl ;

Ttecella_bessel_freq2value = function(
                        Handle : Integer ;
                        Freq : double ;
                        var Value : Integer ) : Integer ; cdecl ;
Ttecella_chan_set_hpf = function(
                        Handle : Integer ;
                        chan : Integer ;
                        Value : Integer) : Integer ; cdecl ;
Ttecella_chan_get_hpf = function(
                        Handle : Integer ;
                        chan : Integer ;
                        var Value : Integer ) : Integer ; cdecl ;

Ttecella_hpf_value2freq = function(
                        Handle : Integer ;
                        Value : Integer ;
                        var Freq : double ) : Integer ; cdecl ;

Ttecella_hpf_freq2value = function(
                        Handle : Integer ;
                        Freq : double ;
                        var Value : Integer ) : Integer ; cdecl ;

//* Vcmd */

Ttecella_stimulus_set =  function(
                         Handle : Integer ;
                         pSegments : Pointer ;
                         segment_count : Integer ;
                         delta_count : Integer ;
                         repeat_count : Integer ;
                         Index : Integer ) : Integer ; cdecl ;

Ttecella_stimulus_get =  function(
                         Handle : Integer ;
                         //var Segments : Array of Ttecella_stimulus_segment ;
                         pSegments : Pointer ;
                         segments_max : Integer ;
                         var segments_in_stimulus : Integer ;
                         var Iterations : Integer ;
                         var Loop : ByteBool ;
                         Index : Integer ) : Integer ; cdecl ;

Ttecella_stimulus_set_ex =  function(
                         Handle : Integer ;
                         pSegments : Pointer ;
                         segment_count : Integer ;
                         delta_count : Integer ;
                         repeat_count : Integer ;
                         Index : Integer ) : Integer ; cdecl ;

Ttecella_stimulus_get_ex =  function(
                         Handle : Integer ;
                         pSegments : Pointer ;
                         segments_max : Integer ;
                         var segments_in_stimulus : Integer ;
                         var Iterations : Integer ;
                         var Loop : ByteBool ;
                         Index : Integer ) : Integer ; cdecl ;


Ttecella_stimulus_set_hold =  function(
                              Handle : Integer ;
                              VHold : Double ;
                              Index : Integer ) : Integer ; cdecl ;

Ttecella_stimulus_sample_count =  function(
                                  pSegments  : Pointer ;
                                  segment_count : Integer ;
                                  sample_period : Double ;
                                  Iteration : Integer ) : Integer ; cdecl ;

Ttecella_stimulus_stream_initialize =  function(
                                      Handle : Integer ;
                                      pBuf : Pointer ;
                                      BufSize : Integer
                                      ) : Integer ; cdecl ;

Ttecella_stimulus_stream_write =  function(
                                      Handle : Integer ;
                                      pBuf : Pointer ;
                                      BufSize : Integer
                                      ) : Integer ; cdecl ;

Ttecella_stimulus_stream_end =  function(
                               Handle : Integer
                                ) : Integer ; cdecl ;

//* Acquire */

Ttecella_acquire_enable_channel =  function(
                                   Handle : Integer ;
                                   channel : Integer ;
                                   enable : ByteBool
                                   ) : Integer ; cdecl ;

Ttecella_acquire_set_buffer_size =  function(
                                    Handle : Integer ;
                                    samples_per_chan : Integer
                                    ) : Integer ; cdecl ;
Ttecella_acquire_start =  function(
                          Handle : Integer ;
                          sample_period_multiplier : Integer ;
                          continuous : ByteBool ;
                          start_stimuli : ByteBool ;
                          continuous_stimuli : ByteBool ;
                          start_on_trigger : ByteBool
                          ) : Integer ; cdecl ;

Ttecella_acquire_start_stimulus =  function(
                                   Handle : Integer ;
                                   stimulus_index : Integer ;
                                   Start : ByteBool ;
                                   continuous : ByteBool ;
                                   sample_period_multiplier : Integer
                                   ) : Integer ; cdecl ;

Ttecella_acquire_stop_stimulus =  function(
                                  Handle : Integer ;
                                  stimulus_index : Integer ;
                                  Continuous : ByteBool
                                  ) : Integer ; cdecl ;

Ttecella_acquire_stop =  function(
                         Handle : Integer
                         ) : Integer ; cdecl ;

Ttecella_acquire_samples_available =  function(
                                      Handle : Integer ;
                                      chan : Integer ;
                                      var samples_available : Integer
                                      ) : Integer ; cdecl ;

Ttecella_acquire_read_d =  function(
                           Handle : Integer ;
                           chan : Integer ;
                           requested_samples : Integer ;
                           data : Pointer ;
                           var actual_samples : Integer ;
                           var first_sample_timestamp : Int64 ;
                           var last_sample_flag : ByteBool
                           ) : Integer ; cdecl ;

Ttecella_acquire_read_i =  function(
                           Handle : Integer ;
                           chan : Integer ;
                           requested_samples : Integer ;
                           data : Pointer ;
                           var actual_samples : Integer ;
                           var first_sample_timestamp : Int64 ;
                           var last_sample_flag : ByteBool
                           ) : Integer ; cdecl ;

Ttecella_acquire_i2d_scale =  function(
                              Handle : Integer ;
                              chan : Integer ;
                              var scale : Double
                              ) : Integer ; cdecl ;

Ttecella_acquire_set_callback =  function(
                                 Handle : Integer ;
                                 CallBackFunction : Pointer ;
                                 Period : Cardinal
                                 ) : Integer ; cdecl ;

Ttecella_auto_comp =  function(
                      Handle : Integer ;
                      v_hold : Double ;
                      t_hold : Double ;
                      v_step : Double ;
                      t_step : Double ;
                      use_leak : ByteBool ;
                      use_digital_leak : ByteBool ;
                      use_cfast : ByteBool ;
                      use_cslow_a : ByteBool ;
                      use_cslow_b : ByteBool ;
                      use_cslow_c : ByteBool ;
                      use_cslow_d : ByteBool ;
                      use_artifact : ByteBool ;
                      under_comp_coefficient : Double ;
                      acq_iterations : Integer ;
                      unused_stimulus_index : Integer
                      ) : Integer ; cdecl ;

Ttecella_auto_calibrate =  function(
                           Handle : Integer ;
                           Enable : ByteBool ;
                           unused_stimulus_index : Integer
                           ) : Integer ; cdecl ;

Ttecella_calibrate_all =  function(
                           Handle : Integer
                           ) : Integer ; cdecl ;

Ttecella_auto_calibrate_get =  function(
                           Handle : Integer ;
                           Chan : Integer ;
                           var OffsetValue : Integer
                           ) : Integer ; cdecl ;

Ttecella_calibrate_save =  function(
                           Handle : Integer ;
                           foldername : PChar ;
                           filename : PChar
                           ) : Integer ; cdecl ;

Ttecella_calibrate_load =  function(
                           Handle : Integer ;
                           foldername : PChar ;
                           filename : PChar
                           ) : Integer ; cdecl ;


Ttecella_auto_offset =  function(
                           Handle : Integer ;
                           JPDelta : Double ;
                           unused_stimulus_index : Integer
                           ) : Integer ; cdecl ;

Ttecella_auto_scale =  function(
                           Handle : Integer ;
                           Enable : ByteBool ;
                           unused_stimulus_index : Integer
                           ) : Integer ; cdecl ;

Ttecella_auto_artifact_enable =  function(
                           Handle : Integer ;
                           Enable : ByteBool ;
                           stimulus_index : Integer
                           ) : Integer ; cdecl ;

Ttecella_auto_artifact_update =  function(
                           Handle : Integer ;
                           VHold : Double ;
                           VStep : Double ;
                           Iterations : Integer ;
                           stimulus_index : Integer
                           ) : Integer ; cdecl ;

Ttecella_user_config_get = function(
                           Handle : Integer ;
                           ConfigNum : Integer ;
                           var hwprops : TTECELLA_HW_PROPS
                            ) : Integer ; cdecl ;

Ttecella_user_config_set = function(
                           Handle : Integer ;
                           ConfigNum : Integer
                            ) : Integer ; cdecl ;

Ttecella_debug = function(
                 FileName : PChar
                 ) : Integer ; cdecl ;

Ttecella_chan_set_digital_leak = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 digital_leak : Double
                                 ) : Integer ; cdecl ;

Ttecella_chan_get_digital_leak = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 var digital_leak : Double
                                 ) : Integer ; cdecl ;

Ttecella_chan_get_digital_leak_enable = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 var Enabled : ByteBool
                                 ) : Integer ; cdecl ;

Ttecella_chan_set_digital_leak_enable = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 Enabled : ByteBool
                                 ) : Integer ; cdecl ;


Ttecella_chan_set_iclamp_enable = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 Enable : ByteBool
                                 ) : Integer ; cdecl ;

Ttecella_chan_get_iclamp_enable = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 var Enable : ByteBool
                                 ) : Integer ; cdecl ;

Ttecella_chan_set_IclampOn  = function(
                                 Handle : Integer ;
                                 Channel : Integer ;
                                 Enable : ByteBool
                                 ) : Integer ; cdecl ;

Ttecella_stimulus_zap = function(
                        Handle : Integer ;
                        duration : Double ;
                        amplitude : Double ;
                        pChannels : Pointer ;
                        channel_count : Integer
                        ) : Integer ; cdecl ;

Ttecella_utility_dac_set = function(
                           Handle : Integer ;
                           Value : Double ;
                           Index : Integer
                           ) : Integer ; cdecl ;

Ttecella_utility_trigger_out = function(
                               Handle : Integer ;
                               Index : Integer
                               ) : Integer ; cdecl ;


function TECELLA_ACQUIRE_CB(
          Handle : Integer ;
          Chan : Integer ;
          SamplesAvailable : Cardinal ) : Integer ;  cdecl ;
          
  procedure Triton_InitialiseBoard ;
  procedure  Triton_Calibrate ;
  function  Triton_IsCalibrated : Boolean ;
  procedure Triton_LoadLibrary  ;

  function  Triton_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }

  procedure Triton_ConfigureHardware(
            EmptyFlagIn : Integer ) ;

  function  Triton_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : ByteBool
            ) : ByteBool ;
  function Triton_StopADC : ByteBool ;
  procedure Triton_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
  procedure Triton_CheckSamplingInterval(
            var SamplingInterval : Double
            ) ;

  function  Triton_MemoryToDACStimulus(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single
          ) : ByteBool ;

function  Triton_MemoryToDACAndDigitalOutStream(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single ;
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : ByteBool              // Output to digital outs
          ) : ByteBool ;

function  Triton_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single ;
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : ByteBool              // Output to digital outs
          ) : ByteBool ;


  function Triton_GetDACUpdateInterval : double ;

  function Triton_StopDAC : ByteBool ;
  procedure Triton_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  Triton_GetLabInterfaceInfo(
            var Model : string ; { Laboratory interface model name/number }
            var ADCMaxChannels : Integer ;        // no. of A/D channels
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double {Min. D/A update interval }
            ) : ByteBool ;

  procedure Triton_GetSourceList( SourceList : TStrings ) ;
  procedure Triton_GetGainList( GainList : TStrings ) ;
  procedure Triton_GetUserConfigList( UserConfigList : TStrings ) ;

  function Triton_GetMaxDACVolts(Chan : Integer) : single ;

  function Triton_ReadADC( Channel : Integer ) : SmallInt ;

  procedure Triton_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure Triton_CloseLaboratoryInterface ;

  procedure Triton_Wait( Delay : Single ) ;

  procedure Triton_CheckError(
          Location : String ;
          Err : Integer
          ) ;

  procedure TritonGetRegisterProperties(
          Reg : Integer ;
          var VMin : Single ;   // Lower limit of register values
          var VMax : Single ;   // Upper limit of register values
          var VStep : Single ;   // Smallest step size of values
          var CanBeDisabled : Boolean ; // Register can be disabled
          var Supported : Boolean     // Register is supported

          ) ;

  procedure TritonGetRegister(
          Reg : Integer ;
          Chan : Integer ;
          var Value : Double ;
          var PercentValue : Double ;
          var Units : String ;
          var Enabled : Boolean );

  procedure TritonSetRegisterPercent(
          Reg : Integer ;
          Chan : Integer ;
          var PercentValue : Double ) ;

  function TritonGetGain( Chan : Integer ) : Integer ;
  procedure TritonSetGain( Chan : Integer ; iGain : Integer ) ;
  function TritonGetSource( Chan : Integer ) : Integer ;
  procedure TritonSetSource( Chan : Integer ; iSource : Integer ) ;

  function TritonGetRegisterEnabled( Reg : Integer ; Chan : Integer ) : ByteBool ;
  procedure TritonSetRegisterEnabled( Reg : Integer ;
                                Chan : Integer ;
                                Enabled : ByteBool ) ;

procedure Triton_Channel_Calibration(
          Chan : Integer ;
          var ChanName : String ;
          var ChanUnits : String ;
          var ChanCalFactor : Single ;
          var ChanScale : Single ) ;

function Triton_CurrentGain(
         Chan : Integer
         ) : Single  ;

function Triton_ClampMode : Integer ;

procedure TritonSetBesselFilter(
          Chan : Integer ;
          Value : Integer ;
          var CutOffFrequency : Single ) ;

procedure TritonAutoCompensate(
          UseCFast : Boolean ;
          UseCslowA  : Boolean ;
          UseCslowB : Boolean ;
          UseCslowC : Boolean ;
          UseCslowD : Boolean ;
          UseAnalogLeakCompensation : Boolean ;
          UseDigitalLeakCompensation : Boolean ;
          UseDigitalArtefactSubtraction : Boolean ;
          CompensationCoeff : Single ;
          VHold : Single ;
          THold : Single ;
          VStep : Single ;
          TStep : Single
          ) ;

procedure TritonJP_AutoZero ;

function TritonGetNumChannels : Integer ;

procedure Triton_DigitalLeakSubtractionEnable(
         Chan : Integer ;
         Enable : Boolean
         ) ;

procedure Triton_AutoArtefactRemovalEnable( Enable : Boolean ) ;

function TritonGetUserConfig : Integer ;

procedure TritonSetUserConfig(
          Config : Integer ) ;

procedure TritonSetDACStreamingEnabled( Enabled : Boolean ) ;
function TritonGetDACStreamingEnabled : Boolean ;

procedure Triton_Zap(
          Duration : Double ;
          Amplitude : Double ;
          ChanNum : Integer
          ) ;

procedure Triton_SetTritonICLAMPOn(
          Value : Boolean
          ) ;
function Triton_GetTritonICLAMPOn : Boolean ;

implementation

uses seslabio ;

var
    TecHandle : Integer ;

    LibraryHnd : Integer ;
    LibraryLoaded : ByteBool ;
    DeviceInitialised : ByteBool ;
    HardwareProps : Ttecella_hw_props ;
    HardwarePropsEX01 : Ttecella_hw_props_ex_01 ;
    FStreamDACSupported : Boolean ;
    FStreamDACEnabled : Boolean ;

    FADCMaxValue : Integer ;
    FADCMinSamplingInterval : Double ;
    FADCMaxSamplingInterval : Double ;
    FADCMaxVolts : Single ;
    FIScaleMin : Array[0..127] of Double ;
    FNumChannels : Integer ;       // No. of channels in sweep
    fNumSamples : Integer ;        // No. samples/channel in sweep
    FSamplingInterval : Double ;   // Sampling interval (s)
    FSamplingIntervalMultiplier : Integer ;
    FSweepDuration : Double ;  // Duration of recording sweep (s)
    FDACMaxVolts : Double ;    // Max. D/A output voltage
    VmBuf : PSmallIntArray ;   // Voltage waveform storage buffer
    FVHold : Double ;          // Default holding level
    FUtilityDAC : Double ;     // Default utility DAC output
    FDigitalOutputs : Integer ; // Default digital outputs
    FOutPointer : Integer ;
    FCurrentClampMode : Boolean ;
    FCircularBufferMode : Boolean ;
    FTriggerMode : Integer ;
    FConfigInUse : Integer ;             // Config currently in use
    FICLAMPOn : Boolean ;
    GetADCSamplesInUse : Boolean ;

        tecella_enumerate : Ttecella_enumerate ;
        tecella_enumerate_get : Ttecella_enumerate_get ;
        tecella_initialize : Ttecella_initialize ;
        tecella_initialize_pair : Ttecella_initialize_pair ;
        tecella_finalize : Ttecella_finalize ;
        tecella_get_lib_props : Ttecella_get_lib_props ;
        tecella_get_hw_props : Ttecella_get_hw_props ;
        tecella_get_hw_props_ex_01 : Ttecella_get_hw_props_ex_01 ;
        tecella_get_reg_props : Ttecella_get_reg_props ;
        //tecella_error_get_last_msg : Ttecella_error_get_last_msg ;
        tecella_error_set_callback : Ttecella_error_set_callback ;
        tecella_error_message : Ttecella_error_message ;
        tecella_chan_set : Ttecella_chan_set ;
        tecella_chan_get : Ttecella_chan_get ;
        tecella_chan_set_pct : Ttecella_chan_set_pct ;
        tecella_chan_get_pct : Ttecella_chan_get_pct ;
        //tecella_get_stimulus_mode : Ttecella_get_stimulus_mode ;
        //tecella_set_stimulus_mode : Ttecella_set_stimulus_mode ;
        //tecella_chan_to_string : Ttecella_chan_to_string ;
        //tecella_chan_get_units : Ttecella_chan_get_units ;
        tecella_chan_set_enable : Ttecella_chan_set_enable ;
        tecella_chan_get_enable : Ttecella_chan_get_enable ;
        tecella_chan_set_gain : Ttecella_chan_set_gain ;
        tecella_chan_get_gain : Ttecella_chan_get_gain ;
        tecella_get_gain_label : Ttecella_get_gain_label ;
        tecella_chan_set_source : Ttecella_chan_set_source ;
        tecella_chan_get_source : Ttecella_chan_get_source ;
        tecella_get_source_label : Ttecella_get_gain_label ;
        tecella_chan_set_bessel : Ttecella_chan_set_bessel ;
        tecella_chan_get_bessel : Ttecella_chan_get_bessel ;
        tecella_bessel_value2freq : Ttecella_bessel_value2freq ;
        tecella_bessel_freq2value : Ttecella_bessel_freq2value ;
        tecella_chan_set_hpf : Ttecella_chan_set_hpf ;
        tecella_chan_get_hpf : Ttecella_chan_get_hpf ;
        tecella_hpf_value2freq : Ttecella_hpf_value2freq ;
        tecella_hpf_freq2value : Ttecella_hpf_freq2value ;
        tecella_stimulus_set : Ttecella_stimulus_set ;
        tecella_stimulus_get : Ttecella_stimulus_get ;
        tecella_stimulus_set_ex : Ttecella_stimulus_set_ex ;
        tecella_stimulus_get_ex : Ttecella_stimulus_get_ex ;
        tecella_stimulus_set_hold : Ttecella_stimulus_set_hold ;
        tecella_stimulus_sample_count : Ttecella_stimulus_sample_count ;
        tecella_acquire_enable_channel : Ttecella_acquire_enable_channel ;
        tecella_acquire_set_buffer_size : Ttecella_acquire_set_buffer_size ;
        tecella_acquire_start : Ttecella_acquire_start ;
        tecella_acquire_start_stimulus : Ttecella_acquire_start_stimulus ;
        tecella_acquire_stop_stimulus : Ttecella_acquire_stop_stimulus ;
        tecella_acquire_stop : Ttecella_acquire_stop ;
        tecella_acquire_samples_available : Ttecella_acquire_samples_available ;
        tecella_acquire_read_d : Ttecella_acquire_read_d ;
        tecella_acquire_read_i : Ttecella_acquire_read_i ;
        tecella_acquire_i2d_scale : Ttecella_acquire_i2d_scale ;
        tecella_acquire_set_callback : Ttecella_acquire_set_callback ;
        tecella_auto_comp : Ttecella_auto_comp ;
        tecella_calibrate_all : Ttecella_calibrate_all  ;
        tecella_calibrate_save : Ttecella_calibrate_save ;
        tecella_calibrate_load : Ttecella_calibrate_load ;

        tecella_auto_calibrate : Ttecella_auto_calibrate  ;
        tecella_auto_calibrate_get : Ttecella_auto_calibrate_get  ;
        tecella_auto_offset : Ttecella_auto_offset  ;
        tecella_auto_scale : Ttecella_auto_scale  ;
        tecella_auto_artifact_enable : Ttecella_auto_artifact_enable ;
        tecella_auto_artifact_update :Ttecella_auto_artifact_update  ;
        tecella_user_config_get : Ttecella_user_config_get ;
        tecella_user_config_set : Ttecella_user_config_set ;
        tecella_debug : Ttecella_debug ;
        tecella_chan_set_digital_leak : Ttecella_chan_set_digital_leak ;
        tecella_chan_get_digital_leak : Ttecella_chan_get_digital_leak ;
        tecella_chan_get_digital_leak_enable : Ttecella_chan_get_digital_leak_enable ;
        tecella_chan_set_digital_leak_enable : Ttecella_chan_set_digital_leak_enable ;
        tecella_chan_set_iclamp_enable : Ttecella_chan_set_iclamp_enable ;
        tecella_chan_get_iclamp_enable : Ttecella_chan_get_iclamp_enable ;
        tecella_chan_set_IclampOn : Ttecella_chan_set_IclampOn ;
        tecella_stimulus_zap : Ttecella_stimulus_zap ;
        tecella_stimulus_stream_initialize : Ttecella_stimulus_stream_initialize ;
        tecella_stimulus_stream_write : Ttecella_stimulus_stream_write ;
        tecella_stimulus_stream_end : Ttecella_stimulus_stream_end ;
        tecella_utility_dac_set : Ttecella_utility_dac_set ;
        tecella_utility_trigger_out : Ttecella_utility_trigger_out ;


procedure Triton_LoadLibrary  ;
{ -------------------------------------
  Load TecellaAmp.DLL library into memory
  -------------------------------------}
var
     TritonDLLPath : String ; // TritonDLL file path
begin

     LoadLibrary(PChar(ExtractFilePath(ParamStr(0)) + 'libgcc_s_dw2-1.dll')) ;
     LoadLibrary(PChar(ExtractFilePath(ParamStr(0)) + 'libusb0.dll')) ;
     LoadLibrary(PChar(ExtractFilePath(ParamStr(0)) + 'mingwm10.dll')) ;
     LoadLibrary(PChar(ExtractFilePath(ParamStr(0)) + 'okFrontPanel.dll')) ;

     // Support DLLs loaded from program folder
     TritonDLLPath := ExtractFilePath(ParamStr(0)) + 'TecellaAmp.DLL' ;

     // Load main library
     LibraryHnd := LoadLibrary(PChar(TritonDLLPath)) ;
     if LibraryHnd <= 0 then
        ShowMessage( format('%s library not found',[TritonDLLPath])) ;

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @tecella_enumerate := Triton_LoadProcedure( LibraryHnd, 'tecella_enumerate' ) ;
        @tecella_enumerate_get := Triton_LoadProcedure( LibraryHnd, 'tecella_enumerate_get' ) ;
        @tecella_initialize := Triton_LoadProcedure( LibraryHnd, 'tecella_initialize' ) ;
        @tecella_initialize_pair := Triton_LoadProcedure( LibraryHnd, 'tecella_initialize_pair' ) ;
        @tecella_finalize  := Triton_LoadProcedure( LibraryHnd, 'tecella_finalize' ) ;
        @tecella_get_lib_props := Triton_LoadProcedure( LibraryHnd, 'tecella_get_lib_props' ) ;
        @tecella_get_hw_props := Triton_LoadProcedure( LibraryHnd, 'tecella_get_hw_props' ) ;
        @tecella_get_hw_props_ex_01 := Triton_LoadProcedure( LibraryHnd, 'tecella_get_hw_props_ex_01' ) ;
        @tecella_get_reg_props := Triton_LoadProcedure( LibraryHnd, 'tecella_get_reg_props' ) ;
        //@tecella_error_get_last_msg := Triton_LoadProcedure( LibraryHnd, 'tecella_error_get_last_msg' ) ;
        @tecella_error_set_callback := Triton_LoadProcedure( LibraryHnd, 'tecella_error_set_callback' ) ;
        @tecella_error_message := Triton_LoadProcedure( LibraryHnd, 'tecella_error_message' ) ;
        @tecella_chan_set := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set' ) ;
        @tecella_chan_get := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get' ) ;
        @tecella_chan_set_pct := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_pct' ) ;
        @tecella_chan_get_pct := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_pct' ) ;
//        @tecella_get_stimulus_mode := Triton_LoadProcedure( LibraryHnd, 'tecella_get_stimulus_mode' ) ;
//        @tecella_set_stimulus_mode := Triton_LoadProcedure( LibraryHnd, 'tecella_set_stimulus_mode' ) ;
        //@tecella_chan_to_string := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_to_string' ) ;
        //@tecella_chan_get_units := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_units' ) ;
        @tecella_chan_set_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_enable' ) ;
        @tecella_chan_get_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_enable' ) ;
        @tecella_chan_set_gain := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_gain' ) ;
        @tecella_chan_get_gain := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_gain' ) ;
        @tecella_get_gain_label := Triton_LoadProcedure( LibraryHnd, 'tecella_get_gain_label' ) ;
        @tecella_chan_set_source := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_source' ) ;
        @tecella_chan_get_source := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_source' ) ;
        @tecella_get_source_label := Triton_LoadProcedure( LibraryHnd, 'tecella_get_source_label' ) ;
        @tecella_chan_set_bessel := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_bessel' ) ;
        @tecella_chan_get_bessel := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_bessel' ) ;
        @tecella_bessel_value2freq := Triton_LoadProcedure( LibraryHnd, 'tecella_bessel_value2freq' ) ;
        @tecella_bessel_freq2value := Triton_LoadProcedure( LibraryHnd, 'tecella_bessel_freq2value' ) ;
        @tecella_chan_set_hpf := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_hpf' ) ;
        @tecella_chan_get_hpf := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_hpf' ) ;
        @tecella_hpf_value2freq := Triton_LoadProcedure( LibraryHnd, 'tecella_hpf_value2freq' ) ;
        @tecella_hpf_freq2value := Triton_LoadProcedure( LibraryHnd, 'tecella_hpf_freq2value' ) ;

        @tecella_stimulus_set := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_set' ) ;
        @tecella_stimulus_get := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_get' ) ;
        @tecella_stimulus_set_ex := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_set_ex' ) ;
        @tecella_stimulus_get_ex := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_get_ex' ) ;
        @tecella_stimulus_set_hold := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_set_hold' ) ;
        @tecella_stimulus_sample_count := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_sample_count' ) ;
        @tecella_stimulus_stream_initialize := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_stream_initialize' ) ;
        @tecella_stimulus_stream_write := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_stream_write' ) ;
        @tecella_stimulus_stream_end := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_stream_end' ) ;

        @tecella_acquire_enable_channel := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_enable_channel' ) ;
        @tecella_acquire_set_buffer_size := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_set_buffer_size' ) ;
        @tecella_acquire_start := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_start' ) ;
        @tecella_acquire_start_stimulus := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_start_stimulus' ) ;
        @tecella_acquire_stop_stimulus := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_stop_stimulus' ) ;
        @tecella_acquire_stop := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_stop' ) ;
        @tecella_acquire_samples_available := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_samples_available' ) ;
        @tecella_acquire_read_d := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_read_d' ) ;
        @tecella_acquire_read_i := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_read_i' ) ;
        @tecella_acquire_i2d_scale := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_i2d_scale' ) ;
        @tecella_acquire_set_callback := Triton_LoadProcedure( LibraryHnd, 'tecella_acquire_set_callback' ) ;
        @tecella_auto_comp := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_comp' ) ;
        @tecella_auto_calibrate := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_calibrate' ) ;
        @tecella_calibrate_all := Triton_LoadProcedure( LibraryHnd, 'tecella_calibrate_all' ) ;
        @tecella_calibrate_save := Triton_LoadProcedure( LibraryHnd, 'tecella_calibrate_save' ) ;
        @tecella_calibrate_load := Triton_LoadProcedure( LibraryHnd, 'tecella_calibrate_load' ) ;
        @tecella_auto_calibrate_get := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_calibrate_get' ) ;
        @tecella_auto_offset := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_offset' ) ;
        @tecella_auto_scale := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_scale' ) ;
        @tecella_auto_artifact_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_artifact_enable' ) ;
        @tecella_auto_artifact_update := Triton_LoadProcedure( LibraryHnd, 'tecella_auto_artifact_update' ) ;
        @tecella_user_config_get := Triton_LoadProcedure( LibraryHnd, 'tecella_user_config_get' ) ;
        @tecella_user_config_set := Triton_LoadProcedure( LibraryHnd, 'tecella_user_config_set' ) ;
        @tecella_debug := Triton_LoadProcedure( LibraryHnd, 'tecella_debug' ) ;
        @tecella_chan_set_digital_leak := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_digital_leak' ) ;
        @tecella_chan_get_digital_leak := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_digital_leak' ) ;
        @tecella_chan_get_digital_leak_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_digital_leak_enable' ) ;
        @tecella_chan_set_digital_leak_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_digital_leak_enable' ) ;
        @tecella_chan_set_iclamp_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_iclamp_enable' ) ;
        @tecella_chan_get_iclamp_enable := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_get_iclamp_enable' ) ;
        @tecella_chan_set_IclampOn := Triton_LoadProcedure( LibraryHnd, 'tecella_chan_set_IclampOn' ) ;
        @tecella_stimulus_zap := Triton_LoadProcedure( LibraryHnd, 'tecella_stimulus_zap' ) ;
        @tecella_utility_dac_set := Triton_LoadProcedure( LibraryHnd, 'tecella_utility_dac_set' ) ;
        @tecella_utility_trigger_out := Triton_LoadProcedure( LibraryHnd, 'tecella_utility_trigger_out' ) ;


        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'TecellaAmp.DLL library not found' ) ;
          LibraryLoaded := False ;
          end ;
     end ;


function  Triton_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }
{ ----------------------------
  Get address of DLL procedure
  ----------------------------}
var
   P : Pointer ;
begin
     P := GetProcAddress(Hnd,PChar(Name)) ;
     if P = Nil then begin
        ShowMessage(format('TecellaAmp.DLL- %s not found',[Name])) ;
        end ;
     Result := P ;
     end ;


function  Triton_GetLabInterfaceInfo(
            var Model : string ; { Laboratory interface model name/number }
            var ADCMaxChannels : Integer ;        // no. of A/D channels
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double {Min. D/A update interval }
            ) : ByteBool ;
// -------------------------
// Get interface information
// -------------------------
var
  LibraryProperties : Ttecella_lib_PROPS ;
  i,ch : Integer ;

begin

     Result := False ;

     if not DeviceInitialised then Triton_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Library properties
     Triton_CheckError( 'tecella_get_lib_props : ',
                        tecella_get_lib_props( LibraryProperties)) ;

     Model := '' ;

     // Name
     for i := 0 to High(HardwareProps.device_name) do begin
         if (HardwareProps.device_name[i] = '?') or
            (HardwareProps.device_name[i] = #0) then Break ;
            Model := Model + HardwareProps.device_name[i] ;
            end ;

     Model := Model + format('. %d channels (Lib. V%d.%d.%d)',
                      [HardwareProps.nchans,
                       LibraryProperties.v_maj,
                       LibraryProperties.v_min,
                       LibraryProperties.v_dot
                       ]) ;

     // Serial numner
     Model := Model + ' (s/n ' ;
     for i := 0 to High(HardwareProps.serial_number) do begin
         if (HardwareProps.serial_number[i] = '?') or
            (HardwareProps.serial_number[i] = #0) then Break ;
            Model := Model + HardwareProps.serial_number[i] ;
            end ;
     Model := Model + ')' ;

     if ANSIContainsText( Model, 'pico' ) then FStreamDACSupported := True
                                          else FStreamDACSupported := False ;

     ADCMaxChannels := HardwareProps.nchans + 1 ;

     ADCMinSamplingInterval := HardwareProps.sample_period_min ;
     FADCMinSamplingInterval := ADCMinSamplingInterval ;
     ADCMaxSamplingInterval := HardwareProps.sample_period_max*SamplingMultiplierMax ;
     FADCMaxSamplingInterval := ADCMaxSamplingInterval ;
     ADCMinValue := -32768 ;
     ADCMaxValue := 32767 ;
     FADCMaxValue := ADCMaxValue ;
     ADCVoltageRanges[0] := 1.0 ;
     NumADCVoltageRanges := 1 ;
     FADCMaxVolts := ADCVoltageRanges[0] ;
     ADCBufferLimit := 32768*2 ;

     // Note. Set to to 1 mV/pA less than range returned by
     // stimulus_value_max because negative limits clips
     // and reports error at -255 mV not -256 mV.
     DACMaxVolts := HardwareProps.stimulus_value_max*(255.0/256.0) ;
     FDACMaxVolts := DACMaxVolts ;

     DACMinUpdateInterval := HardwareProps.sample_period_min ;

     // Patch clamp gain factors

     for ch := 0 to HardwareProps.nchans-1 do begin
         Triton_CheckError( 'TritonSetGain : ',
                            tecella_chan_set_gain( TecHandle,ch,0 )) ;
         // Get current scaling factor
         Triton_CheckError( 'tecella_acquire_i2d_scale',
                            tecella_acquire_i2d_scale(TecHandle,ch,FIScaleMin[ch])) ;
         end ;

     Result := True ;

     end ;


procedure Triton_ConfigureHardware(
            EmptyFlagIn : Integer ) ;
begin
    end ;

procedure Triton_InitialiseBoard ;
// -----------------------
// Initial interface board
// -----------------------
var
    Err,ch : Integer ;
    Enabled : ByteBool ;
    DeviceIndex : Integer ;
    NumDevices : Integer ;
    LibProps : Ttecella_lib_PROPS ;
    HWProps : Ttecella_hw_props ;
    CalibrationFile : String ;
begin

     DeviceInitialised := False ;

     // Load DLL library
     if not LibraryLoaded then Triton_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     //Triton_CheckError('tecella_debug :',tecella_debug(PChar('triton debug.txt')));

     Triton_CheckError('tecella_get_lib_props :',tecella_get_lib_props(LibProps));

     // Enumerate available devices
     Triton_CheckError('tecella_enumerate :',tecella_enumerate( NumDevices )) ;
     if NumDevices < 1 then begin
        ShowMessage( 'No Tecella devices detected.') ;
        Exit ;
        end ;

     // Initialise interface
     DeviceIndex := 0 ;
     Err := tecella_enumerate_get( DeviceIndex , @HardwareProps) ;
     Triton_CheckError('tecella_enumerate_get :',Err) ;

     DeviceIndex := 0 ;
     Err := tecella_initialize( @TecHandle, DeviceIndex ) ;
     Triton_CheckError('tecella_initialize :',Err) ;
     if Err = 0 then DeviceInitialised := True
                else DeviceInitialised := False ;
     if not DeviceInitialised then Exit ;

     // Hardware properties
     Triton_CheckError( 'tecella_get_hw_props : ',
                        tecella_get_hw_props( TecHandle,
                                              HardwareProps)) ;

     Triton_CheckError( 'tecella_get_hw_props_ex_01 : ',
                        tecella_get_hw_props_ex_01( TecHandle,
                                              HardwarePropsEX01 )) ;

     Enabled := True ;

      if ANSIContainsText(
         WideCharToString(HWProps.user_config_name),'ICLAMP') then FCurrentClampMode := True
                                                              else FCurrentClampMode := False ;

     // Enable all channels and set source to None for calibration
     for ch := 0 to HardwareProps.nChans-1 do begin
         Triton_CheckError( 'tecella_chan_set_source : ',
         tecella_chan_set_source( TecHandle, ch, Tecella_Source_None ) );
         Triton_CheckError( 'tecella_acquire_enable_channel : ',
         tecella_acquire_enable_channel( TecHandle, ch, Enabled ) );
         end ;

     CalibrationFile := ExtractFilePath(ParamStr(0)) + TECELLA_CalibrationFileName ;
     if FileExists( CalibrationFile ) then begin
        // Load existing calibration file
        Triton_CheckError( 'tecella_calibrate_load  : ',
                            tecella_calibrate_load ( TecHandle,
                                                  PChar(ExtractFilePath(ParamStr(0))),
                                                  PChar(TECELLA_CalibrationFileName)) ) ;
        end ;

     // Set to config 0
     TritonSetUserConfig( 0 ) ;
     FVHold := 0.0 ;
     FUtilityDAC := 0.0 ;
     FCircularBufferMode := False ;

     end ;

function  Triton_IsCalibrated : Boolean ;
// ----------------------------------------------------------
// Return TRUE if Tecella patch clamp calibration file exists
// ----------------------------------------------------------
var
    CalibrationFile : String ;
begin
     CalibrationFile := ExtractFilePath(ParamStr(0)) + TECELLA_CalibrationFileName ;
     Result := FileExists( CalibrationFile ) ;
     end ;


procedure  Triton_Calibrate ;
// ----------------------------------
// Calbrate all Triton configurations
// ----------------------------------
var
    ch : Integer ;
    Enabled : ByteBool ;
    CalibrationFile : String ;
    iConfig : Integer ;
    HWProps : Ttecella_hw_props ;
    ConfigName : String ;
begin

     // Enable all channels and set source to None for calibration
     for ch := 0 to HardwareProps.nChans-1 do begin
         Triton_CheckError( 'tecella_chan_set_source : ',
         tecella_chan_set_source( TecHandle, ch, Tecella_Source_None ) );
         Enabled := True ;
         Triton_CheckError( 'tecella_acquire_enable_channel : ',
         tecella_acquire_enable_channel( TecHandle, ch, Enabled ) );
         end ;

     CalibrationFile := ExtractFilePath(ParamStr(0)) + TECELLA_CalibrationFileName ;

     for iConfig := 0 to HardwareProps.user_config_count-1 do begin

         tecella_user_config_get( TecHandle, iConfig, HWProps ) ;
         ConfigName := WideCharToString(HWProps.user_config_name) ;
         if ANSIContainsText( ConfigName,'I=0') then continue ;

         tecella_user_config_set( TecHandle, iConfig ) ;

         // Hardware properties
         Triton_CheckError( 'tecella_get_hw_props : ',
                            tecella_get_hw_props( TecHandle,
                                                  HardwareProps)) ;

         Triton_CheckError( 'tecella_get_hw_props_ex_01 : ',
                             tecella_get_hw_props_ex_01( TecHandle,
                                                         HardwarePropsEX01 )) ;

         Enabled := True ;
         Triton_CheckError( 'tecella_auto_calibrate  : ',
                            tecella_auto_calibrate ( TecHandle,Enabled,0 )) ;

         Triton_CheckError( 'tecella_auto_scale   : ',
                               tecella_auto_scale  ( TecHandle,Enabled,0 )) ;

         end ;

     // Save to file
     Triton_CheckError( 'tecella_calibrate_save  : ',
                            tecella_calibrate_save ( TecHandle,
                                                     PChar(ExtractFilePath(ParamStr(0))),
                                                     PChar(TECELLA_CalibrationFileName)) ) ;
     end ;


procedure Triton_GetSourceList( SourceList : TStrings ) ;
// ---------------------------------------------
// Get list of input sources patch clamp channel
// ---------------------------------------------
var
    pLabel : PWideChar ;
    SourceName : String ;
    i : Integer ;
begin
    SourceList.Clear ;
    if HardwareProps.nSources >=1 then SourceList.Add('None') ;
    if HardwareProps.nSources >=2 then SourceList.Add('Head') ;
    if HardwareProps.nSources >=3 then SourceList.Add('Model 1') ;
    if HardwareProps.nSources >=4 then SourceList.Add('Model 2') ;

    SourceList.Clear ;
    for i := 0 to HardwareProps.nSources-1 do begin
      tecella_get_source_label(TecHandle,i,pLabel ) ;
      SourceName := WideCharToString(pLabel) ;
      SourceList.Add(SourceName) ;
      end ;

    end ;


procedure Triton_GetGainList( GainList : TStrings ) ;
// ---------------------------------------------
// Get list of gain setting names
// ---------------------------------------------

var
    pLabel : PWideChar ;
    GainName : String ;
    i : Integer ;
begin
    GainList.Clear ;
    for i := 0 to HardwareProps.ngains-1 do begin
      tecella_get_gain_label(TecHandle,i,pLabel ) ;
      GainName := WideCharToString(pLabel) ;
      GainList.Add(GainName) ;
      end ;
    end ;


procedure Triton_GetUserConfigList( UserConfigList : TStrings ) ;
// -----------------------------------
// Get list of user configs available
// -----------------------------------
var
    i : Integer ;
    HWProps : Ttecella_hw_props ;
    ConfigName : String ;
begin
     // Get all user configs
     UserConfigList.Clear ;
     for i := 0 to HardwareProps.user_config_count-1 do begin
         tecella_user_config_get( TecHandle, i, HWProps ) ;
         ConfigName := WideCharToString(HWProps.user_config_name) ;
         UserConfigList.Add(ConfigName) ;
         end ;
     end ;


function  Triton_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : ByteBool
            ) : ByteBool ;
const
    NumDACs = 2 ;
var
    ch, NumSamplesAvailable,NumSamplesRead : Integer ;
    iBuf : PSmallIntArray ;
    Enabled : Boolean ;
    LastSampleTimeStamp : Int64 ;
    LastSampleFlag : ByteBool ;
  ContinuousRecording : ByteBool ;
  start_stimuli : ByteBool ;
  continuous_stimuli : ByteBool ;
  start_on_trigger : ByteBool ;
  SamplingIntervalMultiplier : Integer ;
    StreamBuf : PSmallIntArray ;
begin
    Result := False ;
    if not DeviceInitialised then Exit ;

    // Stop any A/D activity
    Triton_CheckError( 'tecella_acquire_stop',
                       tecella_acquire_stop(TecHandle)) ;

    FNumChannels := nChannels ;
    fNumSamples := nSamples ;
    FSamplingInterval := dt ;
    FCircularBufferMode := CircularBuffer ;
    FTriggerMode := TriggerMode ;

    FSamplingInterval := dt ;
    Triton_CheckSamplingInterval( FSamplingInterval ) ;
    SamplingIntervalMultiplier := Round( FSamplingInterval/
                                         HardwareProps.sample_period_min ) ;
    FSamplingIntervalMultiplier := SamplingIntervalMultiplier ;
    FSweepDuration := FSamplingInterval*fNumSamples ;
    FOutPointer := 0 ;

    // Set Triton internal buffer size
   Triton_CheckError( 'tecella_acquire_set_buffer_size',
                       tecella_acquire_set_buffer_size( TecHandle, nSamples*SamplingIntervalMultiplier*4) ) ;

    // Clear any samples in queue
    iBuf := Nil ;
    for ch := 1 to nChannels-1 do begin
        // Get no. of samples in queue
        Triton_CheckError( 'tecella_acquire_samples_available',
                           tecella_acquire_samples_available( TecHandle,
                                                              ch-1,
                                                              NumSamplesAvailable )) ;
        // Read them to clear
        if NumSamplesAvailable > 0 then begin
           if iBuf <> Nil then FreeMem( iBuf ) ;
           GetMem( iBuf, NumSamplesAvailable*2 ) ;
           tecella_acquire_read_i( TecHandle,
                                ch-1,
                                NumSamplesAvailable,
                                iBuf,
                                NumSamplesRead,
                                LastSampleTimeStamp,
                                LastSampleFlag ) ;
           end ;
        end ;

    // Enable Triton channels
    for ch := 0 to HardwareProps.nchans-1 do begin
      if ch < (FNumChannels-1) then Enabled := True
                               else Enabled := False ;
      Triton_CheckError( 'tecella_acquire_enable_channel  : ',
                         tecella_acquire_enable_channel(
                         TecHandle,ch,Enabled )) ;
      end ;


    if iBuf <> Nil then FreeMem(iBuf) ;


    if TriggerMode <> tmWaveGen then begin

      // Start recording sweep

      if TriggerMode = tmExtTrigger then start_on_trigger := True
                                    else start_on_trigger := False ;

      FSamplingInterval := dt ;
      Triton_CheckSamplingInterval( FSamplingInterval ) ;
      SamplingIntervalMultiplier := Round( FSamplingInterval/
                                           HardwareProps.sample_period_min ) ;

      ContinuousRecording := true ;
      start_stimuli := false ;
      continuous_stimuli := true ;//True ;

     Triton_CheckError( 'tecella_acquire_start  : ',
                          tecella_acquire_start ( TecHandle,
                                                  SamplingIntervalMultiplier,
                                                  ContinuousRecording,
                                                  start_stimuli,
                                                  continuous_stimuli,
                                                  start_on_trigger )) ;

      end ;

    GetADCSamplesInUse := False ;
    end ;


function Triton_StopADC : ByteBool ;
// -----------------
// Stop A/D sampling
// -----------------
begin
     Result := False ;
     if not DeviceInitialised then Exit ;

    // Clear A/D data buffer
    Triton_CheckError( 'tecella_acquire_stop',
                       tecella_acquire_stop(TecHandle)) ;

    end ;


procedure Triton_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
// ----------------------------------------------------------------
// Get latest A/D samples from device and transfer to output buffer
// ----------------------------------------------------------------
var
    ch, i, j,iVmStart,NumSamplesAvailable,NumSamplesRead,Err,Err0 : Integer ;
    iBuf : PSmallIntArray ;
    fBuf : PDoubleArray ;
    LastSampleTimeStamp : Int64 ;
    LastSampleFlag : ByteBool ;
    NumPointsInBuf : Integer ;   // No. sample points in OutBuf buffer
    EndOfBuf : Integer ;         // Index of last point in OutBuf
    iVHold : Integer ;

begin

     if not DeviceInitialised then Exit ;
     if GetADCSamplesInUse then exit ;
     GetADCSamplesInUse := True ;

    // Get number of samples available
    //Triton_CheckError( 'tecella_acquire_samples_available',
                        Err0 := tecella_acquire_samples_available( TecHandle,
                                                           0,
                                                           NumSamplesAvailable ) ;

    if NumSamplesAvailable <= 0 then begin
       outputDebugString( PChar(format('%d %d',[Err,NumSamplesAvailable]))) ;
       GetADCSamplesInUse := False ;
       Exit ;
       end ;
    Err := 0 ;

    NumPointsInBuf := FNumSamples*FNumChannels ;
    EndOfBuf := NumPointsInBuf - 1 ;

    // Allocate buffer for tecella_acquire_read_i
    GetMem( iBuf, NumSamplesAvailable*2 ) ;

    if FTriggerMode = tmWaveGen then begin
       // Stimulus generation trigger mode: copy voltage stimulus
       iVmStart := FOutPointer div FNumChannels ;
       for i:= iVmStart to Min(iVmStart + NumSamplesAvailable,FNumSamples) -1 do begin
           OutBuf[i*FNumChannels] := VmBuf^[i] ;
           end ;
       end
    else begin
       // Set voltage to holding level (all other trigger modes)
       iVHold := Round((FVHold/FDACMaxVolts)*FADCMaxValue) ;
       j := FOutPointer ;
       for i := 0 to NumSamplesAvailable-1 do begin
           OutBuf[j] := iVHold ;
           j := j + FNumChannels ;
           if j > EndOfBuf then j := j - NumPointsInBuf ;
           end ;
       end ;

    // Copy current channels

    for ch := 1 to FNumChannels-1 do begin

        // Read channel
        Err := tecella_acquire_read_i( TecHandle,
                                ch-1,
                                NumSamplesAvailable,
                                iBuf,
                                NumSamplesRead,
                                LastSampleTimeStamp,
                                LastSampleFlag ) ;
    outputDebugString( PChar(format('%d %d %d',[Err,NumSamplesAvailable,NumSamplesRead]))) ;

        // Copy to output buffer
        if not FCircularBufferMode then begin
           // Single sweep acquisition
           for i := 0 to NumSamplesRead-1 do begin
               j := FOutPointer + (i*FNumChannels) + ch ;
               if j <= EndOfBuf then OutBuf[j] := iBuf^[i] ;
               end ;
           end
        else begin
           // Continuous circular buffer acquisition
           j := FOutPointer + ch ;
           for i := 0 to NumSamplesRead-1 do begin
               OutBuf[j] := iBuf^[i] ;
               j := j + FNumChannels ;
               if j > EndOfBuf then j := j - NumPointsInBuf ;
               end ;
           end ;

        end ;
    i := FOutPointer ;
    FOutPointer := FOutPointer  + NumSamplesRead*FNumChannels ;
    if FOutPointer > EndOfBuf then begin
       if not FCircularBufferMode then begin
       // Single sweep .. Stop any A/D activity
          Triton_CheckError( 'tecella_acquire_stop',
                             tecella_acquire_stop(TecHandle)) ;
          end
       else begin
          // Circular ... back to start of buffer
          FOutPointer := FOutPointer - NumPointsInBuf ;
          end ;
       end ;

    OutBufPointer := FOutPointer ;

 //   if Err <> 0 then
 //      outputDebugString( PChar(format('%d %d %d %d',[Err,i,OutBufPointer,NumSamplesAvailable]))) ;

    FreeMem( iBuf ) ;
    GetADCSamplesInUse := False ;
    end ;


procedure Triton_CheckSamplingInterval(
            var SamplingInterval : Double
            ) ;
// ---------------------------------
// Apply limits to sampling interval
// ---------------------------------
var
    iSamplingIntervalMultiplier : Integer ;
    SamplingIntervalMultiplier : Single ;
begin

     if not DeviceInitialised then Exit ;

     SamplingIntervalMultiplier := SamplingInterval/HardwareProps.sample_period_min ;
     iSamplingIntervalMultiplier := Round(SamplingIntervalMultiplier) ;
     if (SamplingIntervalMultiplier - iSamplingIntervalMultiplier) > 0.05 then Inc(iSamplingIntervalMultiplier) ;
     SamplingInterval := Min(Max( iSamplingIntervalMultiplier*HardwareProps.sample_period_min,
                                  FADCMinSamplingInterval),
                                  FADCMaxSamplingInterval) ;

    end ;


function  Triton_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single ;
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : ByteBool              // Output to digital outs
          ) : ByteBool ;
// ------------------------------------------
// Start D/A stimulus and A/D recording sweep
// ------------------------------------------
begin

    if FStreamDACSupported and FStreamDACEnabled then begin
       Result := Triton_MemoryToDACAndDigitalOutStream( DACValues,
                                                        nChannels,
                                                        nPoints,
                                                        DACUpdateInterval,
                                                        DigValues,
                                                        DigitalInUse ) ;
       end
    else begin
       Result := Triton_MemoryToDACStimulus( DACValues,
                                             nChannels,
                                             nPoints,
                                             DACUpdateInterval ) ;
       end ;
    end ;


function  Triton_MemoryToDACStimulus(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single
          ) : ByteBool ;
// ---------------------------------------------------------------------
// Start D/A stimulus (using stimulus generator) and A/D recording sweep
// ---------------------------------------------------------------------
const
    StimSegmentsSize = 500 ;
    MaxRampSteps = 256 ;
    RampStepSize = 0.0005 ;
type
    TLevel = record
        V : DOuble ;
        Count : Integer ;
        Ramp : Boolean ;
        StartOfRamp : Boolean ;
        EndOfRamp : Boolean ;
        end ;
    TLevelArray = array[0..100000] of TLevel ;
    PLevelArray = ^TLevelArray ;

var
  StimSegments : Array[0..StimSegmentsSize-1] of Ttecella_stimulus_segment ;
  NumStimSegments : Integer ;
  i,j : Integer ;
  V,VScale : Double ;
  StimDuration,StimEndDuration : Double ;
  NumIterations : Integer ;
  DeltaCount : Integer ;
  Index : Integer ;
  ContinuousRecording : ByteBool ;
  MaxStimSegments : Integer ;
  start_stimuli : ByteBool ;
  continuous_stimuli : ByteBool ;
  start_on_trigger : ByteBool ;
  SamplingIntervalMultiplier : Integer ;
  Levels : PLevelArray ;
  nLevels : Integer ;
  OnRamp : Boolean ;
  VMinDiff : Double ;
  iRampStart,iRampEnd : INteger ;
  RampDuration,RampStepDuration,RampsStepSize : Double ;
  NumRampSteps : Integer ;
  MinCount : Integer ;
  VStart : Double ;
begin

    //outputdebugstring(pchar('memoryTodac'));

    Result := False ;
    if not DeviceInitialised then Exit ;

    // Allocate voltage trace buffer
    if VmBuf <> Nil then FreeMem(VmBuf) ;
    GetMem( VmBuf, FNumSamples*2 ) ;
    GetMem( Levels, FNumSamples*SizeOf(TLevel)) ;

    // Max. no. of segments allowed
    MaxStimSegments := Min( StimSegmentsSize,
                            HardwareProps.max_stimulus_segments ) ;

    // Copy command voltage into voltage storage buffer
    for i := 0 to FNumSamples-1 do begin
        j := Min(i,nPoints-1)*nChannels ;
        VmBuf[i] := DACValues[j] ;
        end ;

    // Create stimulus table from Ch.0 of DACValues waveform

    VScale := FDACMaxVolts/(FADCMaxValue) ;
    //if FCurrentClampMode then VScale := VScale*0.1 ;
    //VScale := HardwareProps.stimulus_value_max / FADCMaxValue ;

    // Initialise segment table
    for i := 0 to MaxStimSegments-1 do begin
        StimSegments[i].SegmentType := TECELLA_STIMULUS_SEGMENT_SET;
        StimSegments[i].duration := 0.0 ;
        StimSegments[i].Ramp_Steps := 0 ;
        end ;

    // Initialise levels
    for i := 0 to FNumSamples-1 do begin
        Levels[i].Count := 0 ;
        Levels[i].Ramp := False ;
        Levels[i].StartOfRamp := False ;
        Levels[i].EndOfRamp := False ;
        end ;

    // Split waveform into series of levels
    nLevels := 0 ;
    for i := 1 to FNumSamples-1 do begin
        if (VmBuf[i] <> VmBuf[i-1]) or (i = (FNumSamples-1)) then begin
           Levels[nLevels].V := VmBuf[i-1]*VScale ;
           Inc(nLevels) ;
           end ;
        Inc(Levels[nLevels].Count) ;
        end ;

    // Locate ramps

    MinCount := Max( FNumSamples div 500, 1 ) ;
    for i := 0 to nLevels-1 do begin
        if Levels[i].Count <= MinCount then Levels[i].Ramp := True ;
        end ;

    for i := 1 to nLevels-2 do
        if (Levels[i].Ramp = True) and
           (Levels[i-1].Ramp = False) and
           (Levels[i+1].Ramp = False) then begin
           Levels[i].Ramp := False ;
           end ;

    // Locate start/end of ramps
    OnRamp := False ;
    for i := 0 to nLevels-1 do begin
        if Levels[i].Ramp then begin
           // Start of ramp
           if not OnRamp then Levels[i].StartOfRamp := True ;
           OnRamp := True ;
           end
        else OnRamp := False ;
        end ;

    // End of ramp
    OnRamp := False ;
    for i := nLevels-1 downto 0 do begin
        if Levels[i].Ramp then begin
           // end of ramp
           if not OnRamp then Levels[i].EndOfRamp := True ;
           OnRamp := True ;
           end
        else OnRamp := False ;
        end ;

   // Add waveform segments
    NumStimSegments := 0 ;
    StimDuration := 0.0 ;
    iRampStart := 0 ;
    for i := 0 to nLevels-1 do begin

        if not Levels[i].Ramp then begin
           // Levels
           StimSegments[NumStimSegments].SegmentType := TECELLA_STIMULUS_SEGMENT_SET;
           StimSegments[NumStimSegments].value := Levels[i].V ;
           StimSegments[NumStimSegments].Duration := Levels[i].Count*DACUpdateInterval ;
           StimDuration := StimDuration + StimSegments[NumStimSegments].Duration ;
           NumStimSegments := Min(NumStimSegments+1,(MaxStimSegments-3)) ;
           end
        else begin
           if Levels[i].StartOfRamp then iRampStart := i ;

           if Levels[i].EndOfRamp then begin
              iRampEnd := i ;
              // Determine ramp duration
              RampDuration := 0.0 ;
              for j := iRampStart to iRampEnd do
                  RampDuration := RampDuration + Levels[j].Count*DACUpdateInterval ;
              StimDuration := StimDuration + RampDuration ;

              // Determine step size
              RampsStepSize := Min(Max(
                               (Levels[iRampEnd].V - Levels[iRampStart].V)/200.0,
                               HardwarePropsEX01.stimulus_ramp_step_size_min),
                               HardwarePropsEX01.stimulus_ramp_step_size_max) ;
              RampsStepSize := HardwareProps.stimulus_value_lsb*
                               Sign(Levels[iRampEnd].V - Levels[iRampStart].V)*
                               Max(Round(Abs(RampsStepSize)/HardwareProps.stimulus_value_lsb),1) ;
              if RampsStepSize = 0. then RampsStepSize := HardwareProps.stimulus_value_lsb ;
              // Bug workaround for fixed step size.
              if not FCurrentClampMode then begin
                 RampsStepSize := 0.0005*Sign(Levels[iRampEnd].V - Levels[iRampStart].V) ;
                 if RampsStepSize = 0. then RampsStepSize := 0.0005 ;
                 end
              else RampsStepSize := 1E-11 ;

              NumRampSteps := Max(1,Round(
                              (Levels[iRampEnd].V - Levels[iRampStart].V)/RampsStepSize)) ;

              // Determine step duration
              RampStepDuration := Min( RampDuration/NumRampSteps,
                                       HardwareProps.stimulus_segment_duration_max) ;
              RampStepDuration := HardwareProps.stimulus_segment_duration_lsb*
                                  Max(Round(
                                  RampStepDuration/HardwareProps.stimulus_segment_duration_lsb),1) ;
              VStart := Levels[iRampStart].V ;
              while NumRampSteps > 0 do begin
                    StimSegments[NumStimSegments].Duration := RampStepDuration ;
                    StimSegments[NumStimSegments].SegmentType := TECELLA_STIMULUS_SEGMENT_RAMP ;
                    StimSegments[NumStimSegments].Value_Delta := RampsStepSize ;
                    StimSegments[NumStimSegments].Value := VStart ;
                    StimSegments[NumStimSegments].Ramp_Steps := Min(NumRampSteps,256) ;
                    NumRampSteps := NumRampSteps - StimSegments[NumStimSegments].Ramp_Steps ;
                    VStart := VStart + StimSegments[NumStimSegments].Ramp_Steps*RampsStepSize ;
                    NumStimSegments := Min(NumStimSegments+1,(MaxStimSegments-3)) ;
                    end ;
              end ;
           end ;
        end ;

    // Pad end of voltage stimulus to end of recording sweep
    StimEndDuration := FSweepDuration - StimDuration ;
    if StimEndDuration > 0.0  then begin
       StimSegments[NumStimSegments].SegmentType := TECELLA_STIMULUS_SEGMENT_SET;
       StimSegments[NumStimSegments].value := StimSegments[NumStimSegments-1].value ;
       StimSegments[NumStimSegments].duration := StimEndDuration ;
       Inc(NumStimSegments) ;
       end ;

    // Add 1s to end of sweep
    // (Not sure if this is really necessary or not to avoid hardware buffer overflow errods
    StimSegments[NumStimSegments].SegmentType := TECELLA_STIMULUS_SEGMENT_SET ;
    StimSegments[NumStimSegments].value := StimSegments[NumStimSegments-1].value ;
    StimSegments[NumStimSegments].duration := 1.0 ;//1.0 ;//0.5 ; //0.002 ;
    Inc(NumStimSegments) ;

  { NumSamplesInStim := tecella_stimulus_sample_count( @StimSegments,
                                                       NumStimSegments,
                                                       DACUpdateInterval,
                                                       0 ) ;}
     //outputDebugString( PChar(format('No. samples in stim %d',[NumSamplesInStim]))) ;

    // Set holding voltage
    Index := 0 ;
    Triton_CheckError( 'tecella_stimulus_set_hold',
                       tecella_stimulus_set_hold( TecHandle,
                                                  StimSegments[NumStimSegments-1].value,
                                                  Index)) ;

    // Load stimulus into amplifier
    NumIterations := 1 ;
    DeltaCount := 1 ;
    Index := 0 ;
    //Triton_CheckError( 'tecella_stimulus_set',
                       tecella_stimulus_set( TecHandle,
                                             @StimSegments,
                                             NumStimSegments,
                                             DeltaCount,
                                             NumIterations,
                                             Index ) ;
//                                             ) ;

      // Start recording sweep
      ContinuousRecording := False ;
      start_stimuli := True ;
      continuous_stimuli := False ;
      start_on_trigger := False ;

      FSamplingInterval := DACUpdateInterval ;
      Triton_CheckSamplingInterval( FSamplingInterval ) ;
      SamplingIntervalMultiplier := Round( FSamplingInterval/
                                           HardwareProps.sample_period_min ) ;

      Triton_CheckError( 'tecella_acquire_start  : ',
                          tecella_acquire_start ( TecHandle,
                                                           SamplingIntervalMultiplier,
                                                           ContinuousRecording,
                                                           start_stimuli,
                                                           continuous_stimuli,
                                                           start_on_trigger )) ;

      FreeMem( Levels ) ;

      Result := True ;

      end ;


function  Triton_MemoryToDACAndDigitalOutStream(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          DACUpdateInterval : Single ;
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : ByteBool              // Output to digital outs
          ) : ByteBool ;
// -------------------------------------------------------------------
// Start D/A stimulus (using streamed output) and A/D recording sweep
// -------------------------------------------------------------------
const
    NumPaddingPoints = 10000 ;
    NumStreamWordsPerPoint = 4 ;
var
  i,j,k,iDAC : Integer ;
  VScale : Double ;
  Index : Integer ;
  ContinuousRecording : ByteBool ;

  start_stimuli : ByteBool ;
  continuous_stimuli : ByteBool ;
  start_on_trigger : ByteBool ;
  SamplingIntervalMultiplier : Integer ;
  iPoint : Integer ;
  StreamBuf : PSmallIntArray ;
  NumStream : Integer ;
begin

    //outputdebugstring(pchar('memoryTodac'));

    Result := False ;
    if not DeviceInitialised then Exit ;

    FSamplingInterval := DACUpdateInterval ;
    Triton_CheckSamplingInterval( FSamplingInterval ) ;
    SamplingIntervalMultiplier := Round( FSamplingInterval/
                                         HardwareProps.sample_period_min ) ;

    NumStream := ((FNumSamples*SamplingIntervalMultiplier) + NumPaddingPoints)
                  *NumStreamWordsPerPoint ;

    // Allocate stimulus trace buffer
    if VmBuf <> Nil then FreeMem(VmBuf) ;
    GetMem( VmBuf, Max(FNumSamples,nPoints)*2 ) ;
    GetMem( StreamBuf, NumStream*SizeOf(SmallInt)) ;

    // Copy command stimulus into voltage storage buffer
    for i := 0 to FNumSamples-1 do begin
        j := Min(i,nPoints-1)*nChannels ;
        VmBuf[i] := DACValues[j] ;
        end ;

    // BODGE!!! Divide stimulus by 10 in current clamp mode
    // (not sure why this should be necessary ) 17.01.12
//    if FCurrentClampMode then begin
//       j := 0 ;
//       for i := 0 to FNumSamples-1 do begin
//           DACValues[j] := DACValues[j] div 10 ;
//           j := j + nChannels ;
//           end ;
//       end ;
// Not needed now in V.84

    // Copy to stream buffer (padding end with last sample value)
    j := 0 ;
    iPoint := 0 ;
    while j < NumStream do begin
        for k := 1 to SamplingIntervalMultiplier do begin
            iDAC :=  iPoint*nChannels ;
            if DigitalInUse then StreamBuf^[j] := DigValues[iPoint] shl 4
                            else StreamBuf^[j] := 0 ;

            StreamBuf^[j+1] := -((DACValues[iDAC]) div 16) + 2048 ;
            if nChannels > 1 then StreamBuf^[j+2] := Max((DACValues[iDAC+1] div 32),0)
                             else StreamBuf^[j+2] := 0 ;
            j := j + NumStreamWordsPerPoint ;
            end ;
        iPoint := Min(iPoint+1,nPoints-1) ;
        end ;

    VScale := (FDACMaxVolts/(FADCMaxValue)) ;
    if FCurrentClampMode then VScale := VScale*0.1 ;

    // Set holding voltage
    Index := 0 ;
    Triton_CheckError( 'tecella_stimulus_set_hold',
                       tecella_stimulus_set_hold( TecHandle,
                                                  VMBuf[FNumSamples-1]*VScale,
                                                  Index)) ;

    Triton_CheckError( 'tecella_stimulus_stream_write',
                       tecella_stimulus_stream_write( TecHandle,
                                                      StreamBuf,
                                                      NumStream)) ;

    Triton_CheckError( 'tecella_stimulus_stream_end',
                       tecella_stimulus_stream_end( TecHandle )) ;

    Triton_CheckError( 'tecella_stimulus_stream_initialize',
                       tecella_stimulus_stream_initialize( TecHandle,
                                                           StreamBuf,
                                                           NumStream)) ;

      // Start recording sweep
      ContinuousRecording := true ;
      start_stimuli := True ;
      continuous_stimuli := True ;

      if FTriggerMode = tmExtTrigger then start_on_trigger := True
                                    else start_on_trigger := False ;

      ContinuousRecording := True ;
      start_stimuli := True ;
      continuous_stimuli := True ;
      Triton_CheckError( 'tecella_acquire_start  : ',
                          tecella_acquire_start ( TecHandle,
                                                           SamplingIntervalMultiplier,
                                                           ContinuousRecording,
                                                           start_stimuli,
                                                           continuous_stimuli,
                                                           start_on_trigger )) ;

      FreeMem( StreamBuf ) ;
      Result := True ;

      end ;


function Triton_GetDACUpdateInterval : double ;
begin
    Result := FSamplingInterval ;
    end ;



function Triton_StopDAC : ByteBool ;
//
// Stop D/A output
begin
    Result := False ;
    if not DeviceInitialised then Exit ;
    // Note. stops both D/A and A/D

    Triton_CheckError( 'tecella_acquire_stop',
                       tecella_acquire_stop(TecHandle)) ;

    end ;


procedure Triton_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;
begin

    if not DeviceInitialised then Exit ;
    FVHold := DACVolts[0] ;
    tecella_stimulus_set_hold( TecHandle,FVHold,0) ;

    if (nChannels > 1) and (HardwareProps.n_utility_dacs >= 1) then begin
       FUtilityDAC := DACVolts[1] ;
       tecella_utility_dac_set( TecHandle, DACVolts[1], 0 ) ;
       end ;

    FDigitalOutputs := DigValue ;
    tecella_utility_trigger_out( TecHandle, DigValue ) ;

    end ;


function Triton_GetMaxDACVolts(Chan : Integer) : single ;
// --------------------------------------
// Return upper limit of D/A output range
// --------------------------------------
begin
    if Chan = 0 then begin
       Result := FDACMaxVolts ;
       if FCurrentClampMode then Result := Result*1E9 ;
       end
    else begin
       if HardwareProps.utility_dac_max > 0.0 then
          Result := HardwareProps.utility_dac_max
       else Result := 5.0 ;
       end ;

    end ;



  function Triton_ReadADC( Channel : Integer ) : SmallInt ;
begin
    Result := 0 ;
    end ;



procedure Triton_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
var
    i : Integer ;
begin
    for i := 0 to NumChannels-1 do Offsets[i] := i ;
    end ;


procedure Triton_CloseLaboratoryInterface ;
// --------------------
// Close down interface
// --------------------
begin

    if not DeviceInitialised then Exit ;

    tecella_finalize (TecHandle);

    if VmBuf <> Nil then FreeMem(VmBuf) ;
    VmBuf := Nil ;

    DeviceInitialised := False ;

    end ;

procedure Triton_Channel_Calibration(
          Chan : Integer ;
          var ChanName : String ;
          var ChanUnits : String ;
          var ChanCalFactor : Single ;
          var ChanScale : Single ) ;
// ----------------------------------
// Returns channel calibration factor
// ----------------------------------
begin

    if Chan = 0 then begin
       // Channel 0 (derived from stimulus channel)
       if FCurrentClampMode then begin
          // Current-clamp mode
          ChanName := 'Im' ;
          ChanUnits := 'pA' ;
          ChanCalFactor := (FADCMaxVolts)/(FDACMaxVolts*1E12) ;
          end
       else begin
          // Voltage-clamp mode
          ChanName := 'Vm' ;
          ChanUnits := 'mV' ;
          ChanCalFactor := FADCMaxVolts/(FDACMaxVolts*1E3) ;
          end ;

       ChanScale := 1.0 ;
       end
    else begin
       // All other channels
       if FCurrentClampMode then begin
          // Current-clamp mode
          ChanName := format('Vm%d',[Chan]) ;
          ChanUnits := 'mV' ;
          ChanScale := Triton_CurrentGain(Chan-1) ;
          if FIScaleMin[Chan-1] <> 0.0 then
             ChanCalFactor := 1.0/(FIScaleMin[Chan-1]*32768*1E3) ;
          end
       else begin
          // Voltage-clamp mode
          ChanName := format('Im%d',[Chan]) ;
          ChanUnits := 'pA' ;
          ChanScale := Triton_CurrentGain(Chan-1) ;
          if FIScaleMin[Chan-1] <> 0.0 then
             ChanCalFactor := 1.0/(FIScaleMin[Chan-1]*32768*1E12) ;
          end ;
       end ;
    end ;


function Triton_CurrentGain(
         Chan : Integer
         ) : Single  ;
// ----------------------------------
// Returns current calibration factor
// ----------------------------------
//var
//    iGain : Integer ;
var
      IScale : Double ;
begin
     Result := 1.0 ;
     if not DeviceInitialised then Exit ;
    if Chan < HardwareProps.nchans then begin
       Triton_CheckError( 'tecella_acquire_i2d_scale',
                          tecella_acquire_i2d_scale(TecHandle,Chan,IScale)) ;
       end
    else IScale := 1.0 ;
    Result := FIScaleMin[Chan]/IScale  ;

    end ;

function Triton_ClampMode : Integer ;
// ------------------------------
// Get current/voltage clamp mode
// ------------------------------
begin
    if FCurrentClampMode then Result := 1
                         else Result := 0 ;
    end ;


procedure Triton_Wait( Delay : Single ) ;
begin
    end ;


procedure Triton_CheckError(
          Location : String ;
          Err : Integer
          ) ;
{ --------------------------------------------------------------
  Warn User if the Lab. interface library returns an error
  --------------------------------------------------------------}
var
   s : string ;
begin

     if Err <> 0 then begin
        case Err of

        	TECELLA_ERR_NOT_IMPLEMENTED : s:= 'Not implemented' ;
	        TECELLA_ERR_NOT_SUPPORTED : s:= 'Not supported' ;
	        TECELLA_ERR_BAD_HANDLE : s := 'Bad Handle';
	        TECELLA_ERR_INVALID_CHANNEL : s := 'Invalid channel';
	        TECELLA_ERR_INVALID_STIMULUS : s := 'Invalud stimulus';
	        TECELLA_ERR_INVALID_CHOICE : s := 'Invalid choice';
	        TECELLA_ERR_ALLCHAN_NOT_ALLOWED : s := 'ALLCHAN not allowed';
	        TECELLA_ERR_RETURN_POINTER_NULL : s := 'Return pointer null';
	        TECELLA_ERR_ARGUMENT_POINTER_NULL : s := 'Argument pointer null';
	        TECELLA_ERR_VALUE_OUTSIDE_OF_RANGE : s := 'Value outside of range';
          TECELLA_ERR_INVALID_REGISTER_COMBINATION : s := 'Invalid register combination';
          TECELLA_ERR_DEVICE_CONTENTION : s := 'Device contention' ;
          TECELLA_ERR_INTERNAL : s := 'Internal error';

	        TECELLA_ERR_OKLIB_NOT_FOUND : s := 'OKLIB not found';
	        TECELLA_ERR_DEVICE_OPEN_FAILED : s := 'Device open failed';
	        TECELLA_ERR_DEVICE_INIT_FAILED : s := 'Device init failed';
          TECELLA_ERR_INVALID_DEVICE_INDEX : s := 'Invalid device index';

	//Stimulus errors
	        TECELLA_ERR_STIMULUS_INVALID_SEGMENT_COUNT : s := 'Invalid segment count';
	        TECELLA_ERR_STIMULUS_INVALID_DURATION : s := 'Invalid duration';
	        TECELLA_ERR_STIMULUS_INVALID_VALUE : s := 'Invalid value';
	        TECELLA_ERR_STIMULUS_INVALID_DURATION_DELTA : s := 'Invalid duration delta';
	        TECELLA_ERR_STIMULUS_INVALID_VALUE_DELTA : s := 'Invalid value delta';
	        TECELLA_ERR_STIMULUS_INVALID_RAMP_STEP_COUNT : s := 'Invalid ramp step count';
	        TECELLA_ERR_STIMULUS_INVALID_RAMP_END_VALUE : s := 'Invalid ramp end value';
	        TECELLA_ERR_STIMULUS_INVALID_DELTA_COUNT : s := 'Invalid delta count';
	        TECELLA_ERR_STIMULUS_INVALID_REPEAT_COUNT : s := 'Invalid repeatcount';
	        TECELLA_ERR_STIMULUS_INVALID_SEGMENT_SEQUENCE : s := 'Invalid segment sequence';

	//Acquisition errors
	        TECELLA_ERR_INVALID_SAMPLE_PERIOD : s := 'Invalid sample period' ;
	        TECELLA_ERR_HW_BUFFER_OVERFLOW : s := 'Hardware buffer overflow' ;
	        TECELLA_ERR_SW_BUFFER_OVERFLOW : s := 'Software buffer overflow' ;
	        TECELLA_ERR_ACQ_CRC_FAILED : s := 'CRC failed' ;
	        TECELLA_ERR_CHANNEL_BUFFER_OVERFLOW : s := 'Channel buffer overflow' ;

          else s := 'Unknown error' ;
          end ;
        //s := WideCharToString(tecella_error_message( Err )) ;
        ShowMessage( format('%s : %s (%d)',[Location,s,Err]) ) ;
        end ;
     end ;


procedure TritonSetRegisterPercent(
          Reg : Integer ;
          Chan : Integer ;
          var PercentValue : Double ) ;
// -------------------------------------------
// Set register to percentage of maximum value
// -------------------------------------------
var
    RegProps : Ttecella_reg_props ;
    Value : Double ;
begin

    if Chan >= HardwareProps.nChans then Exit ;

    Triton_CheckError( 'tecella_get_reg_props : ',
                        tecella_get_reg_props( TecHandle,
                                               Reg,
                                               RegProps ));

    if not RegProps.supported then exit ;

    // Keep within range
    PercentValue := Max(Min(PercentValue,100.0),0.0) ;
    // Calculate value
    Value := RegProps.v_min + PercentValue*(RegProps.v_max - RegProps.v_min)*0.01 ;

    Triton_CheckError( 'tecella_chan_set : ',
                       tecella_chan_set( TecHandle,
                                             Reg,
                                             Chan,
                                             Value ) ) ;

    end ;


procedure TritonGetRegisterProperties(
          Reg : Integer ;
          var VMin : Single ;   // Lower limit of register values
          var VMax : Single ;   // Upper limit of register values
          var VStep : Single ;   // Smallest step size of values
          var CanBeDisabled : Boolean ; // Register can be disabled
          var Supported : Boolean       // Register is supported
          ) ;
// --------------------------
// Return register properties
// --------------------------
var
    RegProps : Ttecella_reg_props ;
begin

    Triton_CheckError( 'tecella_get_reg_props : ',
                        tecella_get_reg_props( TecHandle,
                                               Reg,
                                               RegProps ));

    VMin := regProps.v_min ;
    VMax := regProps.v_max ;
    VStep := regProps.v_lsb ;
    CanBeDisabled := regProps.can_be_disabled ;
    Supported := regProps.supported ;

    end ;


procedure TritonGetRegister(
          Reg : Integer ;
          Chan : Integer ;
          var Value : Double ;
          var PercentValue : Double ;
          var Units : String ;
          var Enabled : Boolean ) ;
// -------------------------------------------
// Get register to percentage of maximum value
// -------------------------------------------
var
    RegProps : Ttecella_reg_props ;
    byteEnabled : ByteBool ;
begin

    Enabled := False ;

    Triton_CheckError( 'tecella_get_reg_props : ',
                        tecella_get_reg_props( TecHandle,
                                               Reg,
                                               RegProps ));

    if not RegProps.supported then exit ;
    if Chan >= HardwareProps.nChans then Exit ;

    // Get register value units
    Units := WideCharToString(RegProps.Units) ;

    Units := ANSIReplaceText( Units, '?', '' ) ;
    //Units := ANSIReplaceText( Units, 'O', 'Ohm' ) ;

    // Get current value
    Triton_CheckError( 'tecella_chan_get : ',
                       tecella_chan_get( TecHandle,
                                        Reg,
                                        Chan,
                                        Value )) ;

    // Get current percent value
    Triton_CheckError( 'tecella_chan_get_pct : ',
                       tecella_chan_get_pct( TecHandle,
                                             Reg,
                                             Chan,
                                             PercentValue ) ) ;

    if RegProps.can_be_disabled then begin
       Triton_CheckError( 'tecella_chan_get_enable : ',
                          tecella_chan_get_enable( TecHandle,
                                                   Reg,
                                                   Chan,
                                                  byteEnabled ) ) ;
       Enabled := byteEnabled ;
       end
    else  Enabled := True ;

    end ;


function TritonGetGain(
         Chan : Integer ) : Integer ;
// ---------------------------------------
// Get Triton patch clamp gain for channel
// ---------------------------------------
var
    iGain : Integer ;
begin

    Result := 1 ;
    if Chan >= HardwareProps.nChans then Exit ;

    Triton_CheckError( 'TritonGetGain : ',
                       tecella_chan_get_gain( TecHandle,
                                             Chan,
                                             iGain )) ;
    Result := iGain ;

    end ;


procedure TritonSetGain(
          Chan : Integer ;
          iGain : Integer ) ;
// ---------------------------------------
// Set Triton patch clamp gain for channel
// ---------------------------------------
begin

    if Chan >= HardwareProps.nChans then Exit ;

    iGain := Min(Max(iGain,0),HardwareProps.nGains-1) ;
    Triton_CheckError( 'TritonSetGain : ',
                        tecella_chan_set_gain( TecHandle,
                                               Chan,
                                               iGain )) ;
    end ;


function TritonGetSource(
         Chan : Integer ) : Integer ;
// ---------------------------------------
// Get Triton patch clamp input source for channel
// ---------------------------------------
var
    iSource : Integer ;
begin

    Result := 0 ;
    if Chan >= HardwareProps.nChans then Exit ;

    Triton_CheckError( 'TritonGetSource : ',
                          tecella_chan_get_source( TecHandle,
                                                   Chan,
                                                  iSource )) ;
    Result := iSource ;

    end ;


procedure TritonSetSource(
          Chan : Integer ;
          iSource : Integer ) ;
// ---------------------------------------
// Set Triton patch clamp input source for channel
// ---------------------------------------
begin

    if Chan >= HardwareProps.nChans then Exit ;

    Triton_CheckError( 'TritonSetSource : ',
                       tecella_chan_set_source( TecHandle,
                                                Chan,
                                                iSource )) ;

    end ;


function TritonGetRegisterEnabled(
         Reg : Integer ;
         Chan : Integer ) : ByteBool ;
// ---------------------------------------
// Get Triton register Enable state
// ---------------------------------------
var
    Enabled : ByteBool ;
    RegProps : Ttecella_reg_props ;
begin

    Result := False ;
    if Chan >= HardwareProps.nChans then Exit ;

    // Check whether register can be disabled
    Triton_CheckError( 'tecella_get_reg_props : ',
                        tecella_get_reg_props( TecHandle,
                                               Reg,
                                               RegProps ));

    Result := True ;
    if not RegProps.supported then exit ;
    if not RegProps.can_be_disabled then exit ;

    Triton_CheckError( 'TritonGetRegisterEnable : ',
                        tecella_chan_get_enable( TecHandle,
                                                Reg,
                                                Chan,
                                                Enabled )) ;

    Result := Enabled ;

    end ;


procedure TritonSetRegisterEnabled(
         Reg : Integer ;
         Chan : Integer ;
         Enabled : ByteBool ) ;
// ---------------------------------------
// Get Triton register Enable state
// ---------------------------------------
var
    RegProps : Ttecella_reg_props ;
begin

    if Chan >= HardwareProps.nChans then Exit ;

    Triton_CheckError( 'tecella_get_reg_props : ',
                        tecella_get_reg_props( TecHandle,
                                               Reg,
                                               RegProps ));

    if not RegProps.supported then exit ;
    if not RegProps.can_be_disabled then exit ;

    Triton_CheckError( 'TritonSetRegisterEnable : ',
                        tecella_chan_set_enable( TecHandle,
                                                Reg,
                                                Chan,
                                                Enabled )) ;

    end ;


procedure TritonSetBesselFilter(
          Chan : Integer ;
          Value : Integer ;
          var CutOffFrequency : Single ) ;
//
// Set lpf filter cut-off frequency for selected channel and return cut-off frequency
// -------------------------------------------------------------------------------------
var
    Freq : Double ;
begin

    if Chan >= HardwareProps.nChans then Exit ;
    if (not HardwareProps.supports_bessel) then Exit ;

    Value := Round((Value*0.01)*HardwareProps.bessel_value_max) ;

    Value := Min(Max( Value,
                      HardwareProps.bessel_value_min),
                      HardwareProps.bessel_value_max) ;

    // Set lpf filter
    Triton_CheckError( 'tecella_chan_set_bessel  : ',
                       tecella_chan_set_bessel( TecHandle, Chan, Value )) ;

    // Get cut-off frequency (Hz)
    Triton_CheckError( 'tecella_bessel_value2freq  : ',
                       tecella_bessel_value2freq(TecHandle, Value, Freq )) ;

    CutOffFrequency := Freq ;

    end ;

procedure TritonAutoCompensate(
          UseCFast : Boolean ;
          UseCslowA  : Boolean ;
          UseCslowB : Boolean ;
          UseCslowC : Boolean ;
          UseCslowD : Boolean ;
          UseAnalogLeakCompensation : Boolean ;
          UseDigitalLeakCompensation : Boolean ;
          UseDigitalArtefactSubtraction : Boolean ;
          CompensationCoeff : Single ;
          VHold : Single ;
          THold : Single ;
          VStep : Single ;
          TStep : Single
          ) ;
// ------------------------------------
// Apply automatic capacity compensation
// -------------------------------------
var
    v_hold : Double ;
    t_hold : Double ;
    v_step : Double ;
    t_step : Double ;
    use_analog_leak : ByteBool ;
    use_digital_leak : ByteBool ;
    use_artifact : ByteBool ;
    use_cfast : ByteBool ;
    use_cslow_a : ByteBool ;
    use_cslow_b : ByteBool ;
    use_cslow_c : ByteBool ;
    use_cslow_d : ByteBool ;
    //recalibrate : ByteBool ;
    acq_iterations : Integer ;
    unused_stimulus_index : Integer ;
    CompCoeff : Double ;
begin

     v_hold := VHold ;
     t_hold := THold ;
     v_step := VStep ;
     t_step := TStep ;
     use_analog_leak := UseAnalogLeakCompensation ;
     use_digital_leak := UseDigitalLeakCompensation ;
     use_artifact := UseDigitalArtefactSubtraction ;
     use_cfast := UseCFast ;
     use_cslow_a := UseCslowA ;
     use_cslow_b := UseCslowB ;
     use_cslow_c := UseCslowC ;
     use_cslow_d  := UseCslowD ;
     CompCoeff := CompensationCoeff ;
     //recalibrate  := False ;
     acq_iterations := 20 ;
     unused_stimulus_index := 0 ;
     Triton_CheckError( 'tecella_auto_comp  : ',
                        tecella_auto_comp( TecHandle,
                                           v_hold,
                                           t_hold,
                                           v_step,
                                           t_step,
                                           use_analog_leak,
                                           use_digital_leak,
                                           use_cfast,
                                           use_cslow_a,
                                           use_cslow_b,
                                           use_cslow_c,
                                           use_cslow_d,
				                                   use_artifact,
                                           CompCoeff,
                                           acq_iterations,
                                           unused_stimulus_index
                                           )) ;


     end ;

procedure TritonJP_AutoZero ;
// ------------------------
// Zero junction potentials
// ------------------------
var
    JPDelta : Double ;
    unused_stimulus_index : Integer ;
begin

     unused_stimulus_index := 0 ;
     JPDelta := 0.0 ;
     Triton_CheckError( 'tecella_auto_offset  : ',
                        tecella_auto_offset( TecHandle,
                                           JPDelta,
                                           unused_stimulus_index )) ;
     end ;


function TritonGetNumChannels : Integer ;
// --------------------------------------------
// Return number of Triton patch clamp channels
// --------------------------------------------
begin
    Result := HardwareProps.nChans ;
    end ;


procedure Triton_DigitalLeakSubtractionEnable(
         Chan : Integer ;
         Enable : Boolean
         ) ;
// --------------------------------------------------------
// Enable/disable digital leak subtraction for this channel
// --------------------------------------------------------
var
    Enabled : ByteBool ;
begin
    Enabled := Enable ;
    tecella_chan_set_digital_leak_enable( TecHandle,
                                           Chan,
                                           Enabled ) ;
    end ;


procedure Triton_AutoArtefactRemovalEnable( Enable : Boolean ) ;
// ---------------------------------------
// Enable/disable auto artefact removal
// ---------------------------------------
var
    Enabled : ByteBool ;
begin
    Enabled := Enable ;
    tecella_auto_artifact_enable( TecHandle, Enabled, 0 ) ;
    end ;


function TritonIsIClampSupported : Boolean ;
// --------------------------------------------
// Return TRUE if Tecella device supports current clamp
// --------------------------------------------
begin
    Result := HardwarePropsEX01.supports_iclamp_enable ;
    end ;


procedure TritonSetUserConfig(
          Config : Integer ) ;
// ----------------------
// Set patch clamp config
// ----------------------
var
    //Enabled : ByteBool ;
    ch : Integer ;
begin

     // Set gain to lowest value when changing config to avoid
     // memory access violation if gain setting is out of range
     // the new config
     for ch := 0 to HardwareProps.nchans-1 do begin
         Triton_CheckError( 'TritonSetGain : ',
                            tecella_chan_set_gain( TecHandle,ch,0 )) ;
         end ;

      Config := Min(Max(0,Config),HardwareProps.user_config_count-1) ;
      FConfigInUse := Config ;

      //Triton_CheckError( 'tecella_user_config_set : ',
      tecella_user_config_set( TecHandle, Config) ;//) ;

     // Hardware properties
     Triton_CheckError( 'tecella_get_hw_props : ',
                        tecella_get_hw_props( TecHandle, HardwareProps)) ;
     FADCMinSamplingInterval := HardwareProps.sample_period_min ;
     FADCMaxSamplingInterval := HardwareProps.sample_period_max*SamplingMultiplierMax ;

     Triton_CheckError( 'tecella_get_hw_props_ex_01 : ',
                        tecella_get_hw_props_ex_01( TecHandle, HardwarePropsEX01 )) ;

     //Enabled := True ;

     // Patch clamp gain factors

     for ch := 0 to HardwareProps.nchans-1 do begin
         Triton_CheckError( 'TritonSetGain : ',
                            tecella_chan_set_gain( TecHandle,ch,0 )) ;
         // Get current scaling factor
         Triton_CheckError( 'tecella_acquire_i2d_scale',
                            tecella_acquire_i2d_scale(TecHandle,ch,FIScaleMin[ch])) ;
         end ;

      FDACMaxVolts := HardwareProps.stimulus_value_max*(255.0/256.0) ;

      if ANSIContainsText(
         WideCharToString(HardwareProps.user_config_name),'ICLAMP') then begin
         FCurrentClampMode := True ;
         // Disable current stimulus
         for ch := 0 to HardwareProps.nchans-1 do begin
            Triton_CheckError( 'tecella_chan_set_iclampOn : ',
                            tecella_chan_set_IclampOn( TecHandle,ch,False )) ;

            end ;
         FIclampOn := False ;
         end
      else begin
         FCurrentClampMode := False ;
         end ;

      end ;


function TritonGetUserConfig : Integer ;
// ---------------------------------------
// Get user config setting for patch clamp
// ---------------------------------------
begin

     Result := FConfigInUse ;
     end ;


procedure TritonSetDACStreamingEnabled( Enabled : Boolean ) ;
// ----------------------------
// Enable/disable DAC streaming
// ----------------------------
begin
    FStreamDACEnabled := Enabled ;
    end ;


function TritonGetDACStreamingEnabled : Boolean ;
// ----------------------------
// Enable/disable DAC streaming
// ----------------------------
begin
    Result := FStreamDACEnabled and FStreamDACSupported ;
    end ;


procedure Triton_Zap(
          Duration : Double ;
          Amplitude : Double ;
          ChanNum : Integer
          ) ;
// -----------
// Zap channel
// -----------
var
    ChanList : Array[0..127] of Integer ;
    i,NumChannels : Integer ;
begin

    if ChanNum >= 0 then begin
       ChanList[0] := ChanNum ;
       NumChannels := 1 ;
       end
    else begin
       NumChannels := HardwareProps.nChans-1 ;
       for i := 0 to NumChannels-1 do ChanList[i] := i ;
       end ;

    if HardwareProps.supports_zap then begin
       Triton_CheckError( 'tecella_stimulus_zap   : ',
       tecella_stimulus_zap( TecHandle,
                             Duration,
                             Amplitude,
                             @ChanList,
                             NumChannels )) ;
       end ;
    end ;

procedure Triton_SetTritonICLAMPOn(
          Value : Boolean
          ) ;
// Set ICLAMPOn mode On/Off for all channels
// (ICLAMPOn modes enable current clamp stimulation)
var
    ch : Integer ;
begin
     for ch := 0 to HardwareProps.nchans-1 do begin
         Triton_CheckError( 'tecella_chan_set_iclamp_enable : ',
                            tecella_chan_set_IclampOn( TecHandle,ch,Value )) ;
         end ;
     FIclampOn := Value ;
     end ;


function Triton_GetTritonICLAMPOn : Boolean ;
// --------------------
// Return ICLAMPOn mode
// --------------------
begin
    Result := FIClampOn ;
    end ;

function TECELLA_ACQUIRE_CB(
          Handle : Integer ;
          Chan : Integer ;
          SamplesAvailable : Cardinal ) : Integer ;  cdecl ;
begin
  outputDebugString( PChar(format('called %d',[0]))) ;
  end ;

initialization

    DeviceInitialised := False ;
    FStreamDACEnabled := True ;
    LibraryLoaded := False ;
    VmBuf := Nil ;
    FDACMaxVolts := 1.0 ;
    FConfigInUse := 0 ;



end.
