bits 64

%define CODE_LIMIT 4096

section .data
	msg_done: db "[*] DONE", 10
	msg_done_len: equ $-msg_done
	msg_error_args: db "[X] ERROR ARGS ./compiler archive.lc ",10
	errorargslen: equ $-msg_error_args
	msg_file_open_error: db "[X] FILE OPEN ERROR",10
	file_open_errorlen: equ $-msg_file_open_error
	msg_file_write_error: db "[X] FILE WRITE ERROR",10
	file_write_errorlen: equ $-msg_file_write_error
	msg_lines_archive: db "Number of Lines: "
	msg_lines_archive_len: equ $-msg_lines_archive
	msg_lines_error: db "[X] ERROR ON LINE: "
	msg_lines_error_len: equ $ - msg_lines_error
	msg_lines_cmd_error: db "[X] ERROR CMD NOT FOUND ON LINE: "
	msg_lines_cmd_error_len: equ $ - msg_lines_cmd_error
	hello: db "Welcome To Compiler!",10
	hellolen: equ $-hello
	compiling: db "Compiling: "
	compilinglen: equ $-compiling
	newline: db 10
	; COMMANDS
	; EXIT
	cmd_exit_str: db "exit",0
	; EXEC
	cmd_exec_str: db "exec",0
	; MOV
	cmd_mov_str: db "mov",0 
	cmd_mov_rax: db "rax",0
	cmd_mov_rdi: db "rdi",0
	cmd_mov_rsi: db "rsi",0
	cmd_mov_rdx: db "rdx",0
	; VARIABLES
	cmd_var_str: db "var",0
	; START
	cmd_start_str: db "start",0 
	uefi_start_opcodes:
		db 0x49, 0x89, 0xd4 ; mov r12, rdx
	uefi_start_len: equ $ - uefi_start_opcodes
	; EXEC
	uefi_exec_opcodes:
		db 0x48, 0x8b, 0x45, 0x40    ; mov rax, [r12 + 64] (Pega ConOut da SystemTable)
		db 0x48, 0x89, 0xc1          ; mov rcx, rax        (RCX = ConOut, 1º argumento)
		db 0x48, 0x8b, 0x40, 0x08    ; mov rax, [rax + 8]  (RAX = função OutputString)
		db 0x48, 0x89, 0xf2          ; mov rdx, rsi        (2º argumento = Sua string em RSI)
		db 0x48, 0x83, 0xec, 0x28    ; sub rsp, 32         (Shadow Space)
		db 0xff, 0xd0                ; call rax            (Chama a UEFI)
		db 0x48, 0x83, 0xc4, 0x28    ; add rsp, 32
	uefi_exec_len: equ $ - uefi_exec_opcodes
	; REBOOT
	uefi_reboot_opcodes:
		db 0x48, 0x8b, 0x45, 0x58      ; mov rax, [r12 + 88] (RuntimeServices)
		db 0x48, 0x31, 0xc9            ; xor rcx, rcx (EfiResetCold = 0)
		db 0x48, 0x31, 0xd2            ; xor rdx, rdx (Status Success)
		db 0x45, 0x31, 0xc0            ; xor r8d, r8d (DataSize 0)
		db 0x45, 0x31, 0xc9            ; xor r9d, r9d (ResetData NULL)
		db 0x48, 0x83, 0xec, 0x28      ; sub rsp, 40 (Shadow space + alinhamento)
		db 0xff, 0x50, 0x68            ; call [rax + 104]
		db 0x48, 0x83, 0xc4, 0x28      ; add rsp, 40
	uefi_reboot_len: equ $ - uefi_reboot_opcodes
	
	uefi_newline_data:   db 13, 0, 10, 0, 0, 0, 0, 0 ; CR, LF, NULL
	uefi_only_newline:   db 10, 0, 0, 0, 0, 0       ; LF, NULL
	uefi_only_carriage:  db 13, 0, 0, 0, 0, 0       ; CR, NULL
	; PE HEADER
	align 512
    pe_header_data:
        db 'MZ'
        times 58 db 0
        dd 0x80                 ; Offset para o cabeçalho PE
        times 64 db 0
        db 'PE', 0, 0           ; Signature
        dw 0x8664               ; Machine: x86-64
        dw 2                    ; Number of Sections
        dd 0, 0, 0              ; TimeDateStamp, PointerToSymbolTable, NumberOfSymbols
        dw 0xF0                 ; Size of Optional Header
        dw 0x0023               ; Characteristics (Executable, LargeAddressAware, RelocsStripped)
        
        ; --- OPTIONAL HEADER (PE32+) ---
        dw 0x020B               ; Magic: PE32+ (64-bit)
        db 0, 0                 ; Major/Minor Linker Version
        dd 4096                 ; Size of Code
        dd 4096                 ; Size of Initialized Data
        dd 0                    ; Size of Uninitialized Data
        dd 4096                 ; Address of Entry Point (RVA)
        dd 4096                 ; Base of Code (RVA)
        
        dq 0x400000             ; Image Base (8 bytes)
        dd 4096                 ; Section Alignment
        dd 512                  ; File Alignment
        times 16 db 0           ; OS, User, Subsystem Versions
        dd 12288                ; Size of Image (Headers + Text + Data)
        dd 4096                  ; Size of Headers
        dd 0                    ; CheckSum
        dw 0x000A               ; Subsystem: EFI Application (0x0A)
        dw 0                    ; DllCharacteristics
        dq 0, 0, 0, 0           ; Stack/Heap Reserve/Commit
        dd 0                    ; LoaderFlags
        dd 16                   ; Number of Data Directories
        times 128 db 0          ; Data Directories (Empty)

        ; --- SECTION TABLE ---
        db '.text', 0, 0, 0     ; Name
        dd 4096                 ; VirtualSize
        dd 4096                 ; VirtualAddress
        dd 4096                 ; SizeOfRawData
        dd 4096                 ; PointerToRawData
        times 12 db 0           ; Relocs, Linenumbers, etc.
        dd 0x60000020           ; Characteristics (Code, Execute, Read)

        db '.data', 0, 0, 0     ; Name
        dd 4096                 ; VirtualSize
        dd 8192                 ; VirtualAddress
        dd 4096                 ; SizeOfRawData
        dd 8192                 ; PointerToRawData
        times 12 db 0
        dd 0xC0000040           ; Characteristics (Data, Read, Write)

        times (512 - ($ - pe_header_data)) db 0 ; Padding

section .bss
	end_fd: resq 1
	fd: resq 1
	bytesnum: resq 1
	file: resb 2048
	token: resb 64
	token_len: resq 1
	num_lines: resb 20
	cmd_arg: resb 64
	cmd_arg_len: resq 1
	cmd_arg_2: resb 64
	cmd_arg_2_len: resq 1
	codgen_buffer: resb 32
	is_addr: resq 1
	is_address: resq 1
	var_symbols: resb 2048
	symbol_count: resq 1
	var_name: resb 64
	var_name_len: resq 1
	var_value: resb 64
	var_value_len: resq 1
	code_buffer: resb 4096
	data_buffer: resb 4096
	
section .text
	global _start

; --- FUNCTION: _start ---
_start:
	mov rax, 1
	mov rdi, 1
	mov rsi, hello ; Welcome To Compiler
	mov rdx, hellolen
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, compiling ; Compiling: 
	mov rdx, compilinglen
	syscall

	mov rax, [rsp]
	cmp rax, 3
	jl error_args
	mov rsi,[rsp+16]
	xor rcx, rcx
	
	lea rdi, [code_buffer]
	xor al, al
	mov rcx, 4096
	rep stosb
	
	xor rax, rax
    mov [symbol_count], rax
    mov r14, rax
    mov r15, rax

	jmp strlen_loop

; --- FUNCTION: strlen_loop ---
strlen_loop:
	mov al, byte[rsi+rcx]
	cmp al, 0
	je have_len
	inc rcx
	jmp strlen_loop

; --- FUNCTION: have_len ---
have_len:
	mov rax, 1
	mov rdi, 1
	mov rdx, rcx ; File Name
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, newline ; \n
	mov rdx, 1
	syscall

	jmp openfile

; --- FUNCTION: error_args ---
error_args:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg_error_args ; ERROR ARGS
	mov rdx, errorargslen
	syscall

	mov rax, 60
	xor rdi, rdi 
	syscall

; --- FUNCTION: errorline ---
errorline:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg_lines_error ; ERROR ON LINE
	mov rdx, msg_lines_error_len
	syscall

	call print_r13_as_int

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, cmd_arg_2
    mov rdx, 64
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall

	mov rax, 60
	xor rdi, rdi 
	syscall	

errorlinecmd:
	mov rax, 1
    mov rdi, 1
    mov rsi, msg_lines_cmd_error
    mov rdx, msg_lines_cmd_error_len
    syscall

	call print_r13_as_int

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, cmd_arg_2
    mov rdx, 64
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, cmd_arg
    mov rdx, 64
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, 1
    syscall

	mov rax, 60
	xor rdi, rdi 
	syscall	

; --- FUNCTION: file_open_error ---
file_open_error:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg_file_open_error ; FILE OPEN ERROR
	mov rdx, file_open_errorlen
	syscall
	
	mov rax, 60
	xor rdi, rdi 
	syscall

; --- FUNCTION: file_write_error ---
file_write_error:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg_file_write_error ; FILE WRITE ERROR
	mov rdx, file_write_errorlen
	syscall
	
	mov rax, 60
	xor rdi, rdi 
	syscall

; --- FUNCTION: openfile ---
openfile:
    mov rax, 2
    mov rdi, [rsp+16]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    
    cmp rax, 0
    js file_open_error
    mov [fd], rax

; --- FUNCTION: readfile ---
readfile:
	xor r14, r14
	xor r15, r15
    mov rax, 0
    mov rdi, [fd]
    mov rsi, file
    mov rdx, 1024
    syscall
    
    cmp rax, 0
    js file_open_error
    mov [bytesnum], rax

    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 0x241
    mov rdx, 0644o
    syscall

    cmp rax, 0
    js file_write_error
    mov [end_fd], rax

	xor rbx, rbx
	xor rdi, rdi
	mov r12, [bytesnum]
	mov r13, 1

	jmp cmpchar

; --- FUNCTION: cmpchar ---
cmpchar:
	cmp rbx, r12
	jae endarchive
	mov al, [file + rbx]

	; COMPARING

	cmp al, ' '
	je nextchar

	cmp al, 10
	je charnewline
	
	cmp al, 9
	je nextchar
	
	cmp al, 13
	je nextchar
	
	cmp al, ')'
	je nextchar
	
	cmp al, '"'
	je nextchar
	
	cmp al, ']'
	je nextchar

	; CHARACTER
	xor rdi, rdi
	mov qword [token], 0
	jmp haschar

; --- FUNCTION: nextchar ---
nextchar:
	inc rbx
	jmp cmpchar

; --- FUNCTION: charnewline ---
charnewline:
	inc r13
	inc rbx
	jmp cmpchar

; --- FUNCTION: haschar ---
haschar:
	push rax
    push rcx
    lea rdi, [token]
    xor rax, rax
    mov rcx, 8
    rep stosq
    pop rcx
    pop rax
    xor rdi, rdi

.hascharloop:
    cmp rbx, r12
    jae endcmd
    mov al, [file + rbx]
    
    cmp al, '('
    je endcmd
    cmp al, ' '
    je endcmd
    cmp al, '='
    je endcmd
    
    cmp al, 9
    je .skip
    cmp al, 13
    je .skip
    
    cmp al, 10
    je endcmd
    
    mov [token + rdi], al
    inc rdi
    inc rbx
    jmp .hascharloop

.skip:
    inc rbx
    cmp rbx, r12
    jae endarchive
    jmp .hascharloop
; --- FUNCTION: endcmd ---
endcmd:
	mov byte [token + rdi], 0
    mov [token_len], rdi
    
    cmp rdi, 0
    je .check_end

    mov rax, 1
    mov rdi, 1
    mov qword [codgen_buffer], " > "
    lea rsi, [codgen_buffer]
    mov rdx, 3
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, token
    mov rdx, [token_len]
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
	lea rsi, [token]
    lea rdi, [cmd_exit_str]
    call strcmp
    jc cmdexit
    
    lea rsi, [token]
    lea rdi, [cmd_exec_str]
    call strcmp
    jc cmdexec

    lea rsi, [token]
    lea rdi, [cmd_mov_str]
    call strcmp
    jc cmdmov

    lea rsi, [token]
    lea rdi, [cmd_var_str]
    call strcmp
    jc cmdvar
    
    lea rsi, [token]
    lea rdi, [cmd_start_str]
    call strcmp
    jc cmdstart

    jmp errorlinecmd
    
.check_end:
	cmp rbx, r12
    jae endarchive
    jmp cmpchar
; --- FUNCTION: strcmp ---
strcmp:
    push rax
    push rbx
    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    mov bl, [rdi + rcx]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc rcx
    jmp .loop
.equal:
    stc
    jmp .done
.not_equal:
    clc
.done:
    pop rbx
    pop rax
    ret
; --- FUNCTION: pickarg ---
pickarg:
    push rax
    push rcx
    push rdi
    
    lea rdi, [cmd_arg]
    xor al, al
    mov rcx, 64
    rep stosb
    
    lea rdi, [cmd_arg_2]
    xor al, al
    mov rcx, 64
    rep stosb
    
    pop rdi
    pop rcx
    pop rax
    
    xor rdi, rdi
    
    inc rbx
    
.skip_spaces:
    cmp rbx, r12
    jae errorline
    mov al, [file + rbx]
    cmp al, ' '
    jne .arg_loop
    inc rbx
    jmp .skip_spaces

; --- FUNCTION: .arg_loop ---
.arg_loop:
	cmp rbx, r12
	jge errorline

	mov al, [file + rbx]

	cmp al, ')'
	je .arg_done

	cmp al, ','
	je .more_args
	
	cmp al, '['
	je .first_arg_variable

	cmp al, 10
	je errorline

	mov [cmd_arg + rdi], al
	inc rdi
	inc rbx

	cmp rdi, 63
	jge errorline

	jmp .arg_loop

.more_args:
    mov byte [cmd_arg + rdi], 0
    mov [cmd_arg_len], rdi
	xor rdi, rdi
	inc rbx
	jmp .second_arg_loop
	
.skip_spaces_arg2:
    mov al, [file + rbx]
    cmp al, ' '
    jne .second_arg_loop
    inc rbx
    jmp .skip_spaces_arg2

.first_arg_variable:
	xor rdi, rdi
	jmp .first_arg_variable_loop
	
.first_arg_variable_loop:
	cmp rbx, r12
	jge errorline
	
	mov al, [file + rbx]

	cmp al, ')'
	je errorline

	cmp al, ' '
	je errorline

	cmp al, ']'
	je .first_arg_variable_done

	cmp al, 10
	je errorline

	mov [cmd_arg + rdi], al
	inc rdi
	inc rbx

	jmp .first_arg_variable_loop

.first_arg_variable_done:
	mov byte [cmd_arg + rdi], 0
	mov [cmd_arg_len], rdi
	mov byte [is_address], 1
	xor rdi, rdi
	inc rbx
	
.check_after_var:
	mov al, [file + rbx]
	cmp al, ','
	je .more_args
	cmp al, ')'
	je .arg_done
	cmp al, ' '
	je .skip_space_after
	
.skip_space_after:
	inc rbx
	jmp .check_after_var

.second_arg_loop:
    cmp rbx, r12
    jge errorline
    
    mov al, [file + rbx]
    
    cmp al, ')'
    je .second_arg_done

    cmp al, ' '
    je .second_arg_jump
    
    cmp al, 10
    je .second_arg_done
    
    cmp al, 13
    je .second_arg_jump

    cmp al, '['
    je .second_arg_variable
    
    cmp al, 10
    je errorline
    
    mov [cmd_arg_2 + rdi], al
    inc rdi
    inc rbx
    
    jmp .second_arg_loop

.second_arg_jump:
	inc rbx
	jmp .second_arg_loop

.second_arg_variable:
	xor rdi, rdi
	inc rbx
	jmp .second_arg_variable_loop

.second_arg_variable_loop:
	cmp rbx, r12
	jge errorline
	
	mov al, [file + rbx]

	cmp al, ')'
	je errorline

	cmp al, ' '
	je errorline

	cmp al, ']'
	je .second_arg_variable_done

	cmp al, 10
	je errorline

	mov [cmd_arg_2 + rdi], al
	inc rdi
	inc rbx

	jmp .second_arg_variable_loop

.second_arg_variable_done:
	mov byte [cmd_arg_2 + rdi], 0
	mov [cmd_arg_2_len], rdi
	mov byte [is_addr], 1
	inc rbx
	ret

.second_arg_done:
    mov byte [cmd_arg_2 + rdi], 0
    mov [cmd_arg_2_len], rdi
    mov byte [is_addr], 0
    ret

.arg_done:
    mov byte [cmd_arg + rdi], 0
    mov [cmd_arg_len], rdi
    inc rbx
    ret

; --- FUNCTION: cmdexit ---
cmdexit:
    call pickarg
    call atoi_arg

    mov byte [codgen_buffer + 0], 0x48
    mov byte [codgen_buffer + 1], 0xB8
    mov qword [codgen_buffer + 2], 60

    mov byte [codgen_buffer + 10], 0x48
    mov byte [codgen_buffer + 11], 0xBF
    mov [codgen_buffer + 12], rax

    mov word [codgen_buffer + 20], 0x050F

    lea rsi, [codgen_buffer]
    lea rdi, [code_buffer + r14]
    mov rcx, 22
    rep movsb
    
    add r14, 22
        
    jmp cmpchar
; --- FUNCTION: cmdexit ---
; -------------------------
; --- FUNCTION: cmdexec ---
cmdexec:
    call pickarg
    call atoi_arg
    
    cmp rax, 1
    je .inject_print
    cmp rax, 2
    je .inject_reboot
    cmp rax, 3
    je .inject_newline
    cmp rax, 4
    je .inject_only_newline
    cmp rax, 5
    je .inject_only_carriage
    jmp cmpchar

.inject_print:           ; exec(1) - PRINT
    lea rsi, [uefi_exec_opcodes]
    mov rcx, uefi_exec_len
    jmp .copy

.inject_reboot:         ; exec(2) - REBOOT
    lea rsi, [uefi_reboot_opcodes]
    mov rcx, uefi_reboot_len
    jmp .copy
    
.inject_newline:        ; exec(3) - CRLF
    lea rsi, [uefi_newline_data]
    mov rcx, 6
    jmp .inject_control

.inject_only_newline:   ; exec(4) - LF
    lea rsi, [uefi_only_newline]
    mov rcx, 4
    jmp .inject_control

.inject_only_carriage:  ; exec(5) - CR
    lea rsi, [uefi_only_carriage]
    mov rcx, 4
    jmp .inject_control

.inject_control:
    mov rax, 0x402000
    add rax, r15
    push rax

    push rsi
    push rcx
    lea rdi, [data_buffer + r15]
    rep movsb
    
    add r15, rcx
    add r15, 7
    and r15, -8
    pop rcx
    pop rsi

    mov byte [code_buffer + r14], 0x48
    mov byte [code_buffer + r14 + 1], 0xBE
    pop rax
    mov [code_buffer + r14 + 2], rax
    add r14, 10

    lea rsi, [uefi_exec_opcodes]
    mov rcx, uefi_exec_len
    lea rdi, [code_buffer + r14]
    rep movsb
    add r14, rcx

    jmp cmpchar

.copy:
    lea rdi, [code_buffer + r14]
    mov r11, rcx 
    rep movsb
    add r14, r11 
    
    jmp cmpchar
; --- FUNCTION: cmdexec ---
; -------------------------
; --- FUNCTION: cmdmov ---
cmdmov:
	mov byte [is_addr], 0
	mov byte [is_address], 0
	
	call pickarg
	
	cmp [is_address], 1
	je cmdmov_reg_to_var
	
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_arg_2
	mov rdx, [cmd_arg_2_len]
	syscall
	
	mov eax, [cmd_mov_rax]
	mov edx, [cmd_arg]
	cmp eax, edx
	je cmdmov_rax

	mov eax, [cmd_mov_rdi]
	cmp eax, edx
	je cmdmov_rdi

	mov eax, [cmd_mov_rsi]
	cmp eax, edx
	je cmdmov_rsi

	mov eax, [cmd_mov_rdx]
	cmp eax, edx
	je cmdmov_rdx

	cmp word [cmd_arg], "al"
	je cmdmov_al
	
	jmp errorline

cmdmov_reg_to_var:
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_arg_2
	mov rdx, [cmd_arg_2_len]
	syscall
	
	mov byte [is_addr], 0
	mov byte [is_address], 1
	
	lea rsi, [cmd_arg_2]
    lea rdi, [cmd_mov_rax]
    call strcmp
	jc cmdmov_rax
	
	lea rsi, [cmd_arg_2]
    lea rdi, [cmd_mov_rdi]
    call strcmp
	jc cmdmov_rdi
	
	lea rsi, [cmd_arg_2]
    lea rdi, [cmd_mov_rsi]
    call strcmp
    jc cmdmov_rsi
	
	lea rsi, [cmd_arg_2]
    lea rdi, [cmd_mov_rdx]
    call strcmp
    jc cmdmov_rdx
	
	cmp word [cmd_arg_2], "al"
	je cmdmov_al
	
	jmp errorline

cmdmov_rax:
	cmp byte [is_addr], 1
	je .mov_rax_mem
	cmp byte [is_address], 1
	je .mov_rax_mem

	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xB8

	call atoi_arg_2

	mov [codgen_buffer + 2], rax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 10
	rep movsb
	
	add r14, 10

	jmp cmpchar

.mov_rax_mem:
    mov al, 0x05
    jmp generic_mov_mem

cmdmov_rdi:
	cmp byte [is_addr], 1
	je .mov_rdi_mem
	cmp byte [is_address], 1
	je .mov_rdi_mem
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBF

	call atoi_arg_2

	mov [codgen_buffer + 2], rax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 10
	rep movsb
	
	add r14, 10

	jmp cmpchar
	
.mov_rdi_mem:
    mov al, 0x3D
    jmp generic_mov_mem

cmdmov_rsi:
	cmp byte [is_addr], 1
	je .mov_rsi_mem
	cmp byte [is_address], 1
	je .mov_rsi_fmem
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBE

	call atoi_arg_2

	mov [codgen_buffer + 2], rax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 10
	rep movsb
	
	add r14, 10

	jmp cmpchar

.mov_rsi_mem:
	mov qword [codgen_buffer], 0
    mov qword [codgen_buffer + 2], 0

    mov byte [codgen_buffer + 0], 0x48
    mov byte [codgen_buffer + 1], 0x8D
    mov byte [codgen_buffer + 2], 0x35

    call var_to_addr
    
    mov r8, CODE_LIMIT
    add r8, rax         
    mov rcx, r14
    add rcx, 7
    sub r8, rcx
    mov [codgen_buffer + 3], r8d

    lea rsi, [codgen_buffer]
    lea rdi, [code_buffer + r14]
    mov rcx, 7
    rep movsb
    
    add r14, 7
    mov byte [is_addr], 0
    jmp cmpchar

.mov_rsi_fmem:
    mov al, 0x35
    jmp generic_mov_mem

cmdmov_rdx:
	cmp byte [is_addr], 1
	je .mov_rdx_mem
	cmp byte [is_address], 1
	je .mov_rdx_mem
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBA

	call atoi_arg_2

	mov [codgen_buffer + 2], rax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 10
	rep movsb
	
	add r14, 10

	jmp cmpchar
	
.mov_rdx_mem:
	mov al, 0x15
	jmp generic_mov_mem

cmdmov_al:
	cmp byte [is_addr], 1
	je .mov_al_mem
	cmp byte [is_address], 1
	je .mov_al_fmem
	
	mov byte [codgen_buffer + 0], 0xB0

	call atoi_arg_2

	mov [codgen_buffer + 1], eax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 2
	rep movsb
	
	add r14, 2

	jmp cmpchar
	
.mov_al_mem:
    mov byte [codgen_buffer + 0], 0x8A
    mov byte [codgen_buffer + 1], 0x05
    
    call var_to_addr
    
    mov r8, CODE_LIMIT
    add r8, rax
    mov rcx, r14
    add rcx, 6
    sub r8, rcx
    
    mov [codgen_buffer + 2], r8d
    
    lea rsi, [codgen_buffer]
    lea rdi, [code_buffer + r14]
    mov rcx, 6
    rep movsb
    
    add r14, 6
    jmp cmpchar

.mov_al_fmem:
	mov byte [codgen_buffer + 0], 0x88
    mov byte [codgen_buffer + 1], 0x05
    
    call var_to_addr
    
    mov r8, CODE_LIMIT
    add r8, rax
    mov rcx, r14
    add rcx, 6
    sub r8, rcx
    
    mov [codgen_buffer + 2], r8d
    
    lea rsi, [codgen_buffer]
    lea rdi, [code_buffer + r14]
    mov rcx, 6
    rep movsb
    
    add r14, 6
    jmp cmpchar

generic_mov_mem:
	push rax
    lea rdi, [codgen_buffer]
    xor rax, rax
    mov rcx, 4
    rep stosq
    pop rax
    
    mov byte [codgen_buffer + 0], 0x48
    mov [codgen_buffer + 2], al
    cmp [is_addr], 1
    je .mov_is_addr
    cmp [is_address], 1
    je .mov_is_address
    
    jmp .continue_gen
    
.mov_is_addr:
	mov byte [codgen_buffer + 1], 0x8B
	jmp .continue_gen

.mov_is_address:
	mov byte [codgen_buffer + 1], 0x89
	jmp .continue_gen
    
.continue_gen:
	mov rax, 1
    mov rdi, 1
    mov rsi, cmd_arg
    mov rdx, 32
    syscall

	call var_to_addr
    
    mov r8, CODE_LIMIT
    add r8, rax
    mov rcx, r14
    add rcx, 7
    sub r8, rcx
    mov [codgen_buffer + 3], r8d

    lea rsi, [codgen_buffer]
    lea rdi, [code_buffer + r14]
    mov rcx, 7
    rep movsb
    
    add r14, 7
    mov byte [is_addr], 0
    mov byte [is_address], 0
    jmp cmpchar
    
; --- FUNCTION: cmdmov ---
; ------------------------
var_to_addr:
    push rsi
    push rdi
    push rcx
    push rbx

    mov rcx, [symbol_count]
    xor rbx, rbx

    cmp byte [is_addr], 1
    je .use_arg2
    cmp byte [is_address], 1
    je .use_arg1
    lea rsi, [cmd_arg]
    jmp .search_loop

.use_arg1:
    lea rsi, [cmd_arg]
        
    mov rax, 1
    mov rdi, 1
    mov rdx, [cmd_arg_len]
    syscall
    jmp .search_loop

.use_arg2:
    lea rsi, [cmd_arg_2]
        
    mov rax, 1
    mov rdi, 1
    mov rdx, [cmd_arg_2_len]
    syscall
    jmp .search_loop

.search_loop:
    cmp rbx, rcx
    jge .not_found

    lea rdi, [var_symbols + rbx]
    xor r10, r10

.compare_loop:
    mov al, [rsi + r10]
    mov dl, [rdi + r10]
    cmp al, dl
    jne .next_symbol
    cmp al, 0
    je .found
    inc r10
    cmp r10, 32
    jl .compare_loop

.next_symbol:
    add rbx, 40
    jmp .search_loop

.found:
    mov rax, [var_symbols + rbx + 32]
    pop rbx
    pop rcx
    pop rdi
    pop rsi
    ret

.not_found:
    jmp errorlinecmd
; -----------------------
; --- FUNCTION: cmdvar ---
cmdvar:
	push rbx
    lea rdi, [var_name]
    xor rax, rax
    mov rcx, 8
    rep stosq
    pop rbx
    inc rbx

.skip_1:
    mov al, [file + rbx]
    cmp al, ' '
    jne .get_name
    inc rbx
    jmp .skip_1

.get_name:
    xor rdi, rdi
.name_loop:
    mov al, [file + rbx]
    cmp al, ' '
    je .after_name_skip
    cmp al, '='
    je .after_name
    mov [var_name + rdi], al
    inc rdi
    inc rbx
    jmp .name_loop

.after_name_skip:
    inc rbx
    mov al, [file + rbx]
    cmp al, '='
    je .after_name
    cmp al, ' '
    je .after_name_skip
    jmp errorline

.after_name:
    mov byte [var_name + rdi], 0
    mov [var_name_len], rdi
    cmp [var_name_len], 32
    je errorline

.skip_2:
    mov al, [file + rbx]
    cmp al, '='
    je .found_equal
    inc rbx
    jmp .skip_2

.found_equal:
    inc rbx

.skip_3:
    mov al, [file + rbx]
    cmp al, '"'
    je .get_string
    cmp al, ' '
    je .jump_space
    jmp .get_int

.jump_space:
	inc rbx
	jmp .skip_3

.get_string:
    inc rbx
    xor rdi, rdi
.string_loop:
    mov al, [file + rbx]
    cmp al, '"'
    je .string_done
    cmp al, 10
    je errorline
    mov [var_value + rdi], al
    inc rdi
    inc rbx
    mov [var_value + rdi], 0
    inc rdi
    jmp .string_loop

.string_done:
    mov byte [var_value + rdi], 0
    inc rdi
    mov byte [var_value + rdi], 0
    inc rdi
    mov [var_value_len], rdi
    inc rbx
    jmp .done
.get_int:
    xor rdi, rdi
.int_loop:
    mov al, [file + rbx]
    
    cmp al, 10
    je .doneint
    cmp al, 13
    je .doneint
    cmp al, ' '
    je .doneint
    
    cmp al, '0'
    jl .next_int
    cmp al, '9'
    jg .next_int

    mov [var_value + rdi], al
    inc rdi
    
.next_int:
    inc rbx
    jmp .int_loop
    
.doneint:
    call atoi_int_var
    
    mov [var_value], rax
    
    mov qword [var_value_len], 8
    
    jmp .done

.done:
    cmp qword [var_value_len], 8
    je .skip_len_fix
    mov [var_value_len], rdi
.skip_len_fix:
    mov rdi, var_symbols
    mov rax, [symbol_count]
    add rdi, rax
    
    push rdi
    
    lea rsi, [var_name]
    mov rcx, 4
    rep movsq
    
    pop rdi
    
    mov [rdi + 32], r15     

    lea rsi, [var_value]
    mov rdi, data_buffer
    add rdi, r15
    mov rcx, [var_value_len]
    rep movsb

    mov rax, [var_value_len]
    add r15, rax
    
    add r15, 1
    and r15, -2
    
    add qword [symbol_count], 40

    xor rax, rax
    lea rdi, [var_name]
    mov rcx, 8
    rep stosq
    
    lea rdi, [var_value]
    mov rcx, 8
    rep stosq

    mov qword [var_value_len], 0

    inc rbx
    jmp cmpchar

atoi_int_var:
	xor rax, rax
	xor rcx, rcx

.loop_int_var:
	movzx rdx, byte [var_value + rcx]
    test dl, dl
    jz .done_var_int
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp .loop_int_var
    
.done_var_int:
	ret
; --- FUNCTION: cmdstart ---
cmdstart:
	call pickarg

	lea rsi, [uefi_start_opcodes]
	mov rcx, uefi_start_len
	jmp .copystart

.copystart:
    lea rdi, [code_buffer + r14]
    mov r11, rcx 
    rep movsb
    add r14, r11 
    
    jmp cmpchar
	
; --- FUNCTION: write_pe_header ---
write_pe_header:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 8
    mov rdi, [end_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, pe_header_data 
    mov rdx, 512            
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
; --- FUNCTION: endarchive ---
endarchive:
    call write_pe_header

    mov rax, 8
    mov rdi, [end_fd]
    mov rsi, 4096
    xor rdx, rdx
    syscall

    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, code_buffer
    mov rdx, r14
    syscall

    mov rax, 8
    mov rdi, [end_fd]
    mov rsi, 8192
    xor rdx, rdx
    syscall

    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, data_buffer
    mov rdx, r15
    syscall

    mov rax, 8
    mov rdi, [end_fd]
    mov rsi, 12287
    xor rdx, rdx
    syscall
    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, 3
    mov rdi, [fd]
    syscall
    mov rax, 3
    mov rdi, [end_fd]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_done  ; "[*] DONE"
    mov rdx, msg_done_len
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall
; --- FUNCTION: endarchive ---

; --- FUNCTION: print_r13_as_int ---
print_r13_as_int:
    mov rax, r13
    mov rdi, num_lines
    add rdi, 19
    mov byte [rdi], 0
    mov rbx, 10

; --- FUNCTION: conver_loop ---
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop

    mov rsi, rdi
    mov rdx, num_lines
    add rdx, 19
    sub rdx, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    ret
; --- FUNCTION: print_r13_as_int ---

; --- FUNCTION: atoi_arg ---
atoi_arg:
	xor rax, rax
	xor rcx, rcx

.loop:
	movzx rdx, byte [cmd_arg + rcx]
    test dl, dl
    jz .done
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp .loop
.done:
    ret
; --- FUNCTION: atoi_arg ---
; --- FUNCTION: atoi_arg_2 ---
atoi_arg_2:
	xor rax, rax
	xor rcx, rcx

.loop_2:
	movzx rdx, byte [cmd_arg_2 + rcx]
    test dl, dl
    jz .done_2
    
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    
    inc rcx
    jmp .loop_2
.done_2:
    ret
; --- FUNCTION: atoi_arg_2 ---
