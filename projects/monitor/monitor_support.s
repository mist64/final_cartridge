.global _basic_warm_start
_basic_warm_start := $E37B

.segment        "LOADADDR"
.addr   *+2

.segment "monitor_support"
.global _disable_rom
_disable_rom:
.global _enable_rom
_enable_rom:
.global jfast_format
jfast_format:
.global set_io_vectors
set_io_vectors:
.global set_io_vectors_with_hidden_rom
set_io_vectors_with_hidden_rom:
    rts