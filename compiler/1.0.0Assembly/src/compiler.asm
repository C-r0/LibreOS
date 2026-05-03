bits 64

%define CODE_LIMIT 2048

section .data
	msg_done: db "[*] DONE", 10
	msg_done_len: equ $-msg_done
	msg_error_args: db "[X] ERROR ARGS ./compiler main.lc main.bin",10
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
	mov byte [symbol_count], 0
	
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
    jmp haschar

.skip:
    inc rbx
    jmp haschar
; --- FUNCTION: endcmd ---
endcmd:
	mov byte [token + rdi], 0
    mov [token_len], rdi
    
    cmp rdi, 0
    je cmpchar

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

    jmp errorlinecmd
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
	inc rbx
	xor rdi, rdi

; --- FUNCTION: .arg_loop ---
.arg_loop:
	cmp rbx, r12
	jge errorline

	mov al, [file + rbx]

	cmp al, ')'
	je .arg_done

	cmp al, ','
	je .more_args

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
	xor rdi, rdi
	inc rbx
	jmp .second_arg_loop

.second_arg_loop:
    cmp rbx, r12
    jge errorline
    
    mov al, [file + rbx]
    
    cmp al, ')'
    je .second_arg_done

    cmp al, ' '
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
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_exit_str
	mov rdx, 4

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
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_exec_str
	mov rdx, 4

	.clean_line:
        inc rbx
        cmp byte [file + rbx], 10
        jne .clean_line
	mov word [codgen_buffer + 0], 0x050F

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 2
	rep movsb
	
	add r14, 2

	jmp cmpchar
; --- FUNCTION: cmdexec ---
; -------------------------
; --- FUNCTION: cmdmov ---
cmdmov:
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_mov_str
	mov rdx, 4
	
	mov byte [is_addr], 0
	call pickarg
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

cmdmov_rax:
	cmp byte [is_addr], 1
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
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBF

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

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
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBE

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

	lea rsi, [codgen_buffer]
	lea rdi, [code_buffer + r14]
	mov rcx, 10
	rep movsb
	
	add r14, 10

	jmp cmpchar

.mov_rsi_mem:
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

cmdmov_rdx:
	cmp byte [is_addr], 1
	je .mov_rdx_mem
	
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBA

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

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

generic_mov_mem:
    push rax
    
    mov byte [codgen_buffer + 0], 0x48
    mov byte [codgen_buffer + 1], 0x8B
    pop rax
    mov [codgen_buffer + 2], al

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
; --- FUNCTION: cmdmov ---
; ------------------------
var_to_addr:
    push rsi
    push rdi
    push rcx
    push rbx

    xor rbx, rbx
    mov rcx, [symbol_count]

.search_loop:
    cmp rbx, rcx
    jge .not_found

    lea rsi, [cmd_arg_2]
    lea rdi, [var_symbols + rbx]

    mov r10, 0
.compare_name:
    mov al, [rsi + r10]
    mov dl, [rdi + r10]
    cmp al, dl
    jne .next_symbol
    
    cmp al, 0
    je .found
    
    inc r10
    cmp r10, 32
    jl .compare_name

.found:
    mov rax, [var_symbols + rbx + 32]
    jmp .exit

.next_symbol:
    add rbx, 40
    jmp .search_loop

.not_found:
    jmp errorline

.exit:
    pop rbx
    pop rcx
    pop rdi
    pop rsi
    ret
; -----------------------
; --- FUNCTION: cmdvar ---
cmdvar:
	mov rax, 1
	mov rdi, 1
	mov rsi, cmd_var_str
	mov rdx, 4
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
    je .done
    cmp al, 10
    je errorline
    mov [var_value + rdi], al
    inc rdi
    inc rbx
    jmp .string_loop

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
	mov byte [var_value + rdi], 0
    mov [var_value_len], rdi

    mov rdi, var_symbols
    add rdi, [symbol_count]
    push rdi
    
    lea rsi, [var_name]
    mov rcx, 32
    rep movsb
    
    pop rdi
    
    mov [rdi + 32], r15
    
    add qword [symbol_count], 40

    lea rsi, [var_value]
    lea rdi, [data_buffer + r15]
    mov rcx, [var_value_len]
    rep movsb

    add r15, [var_value_len]
    
	xor rax, rax
    mov rdi, var_name
    mov rcx, 8
    rep stosq
    
    mov rdi, var_value
    mov rcx, 8
    rep stosq
    
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
; --- FUNCTION: cmdvar ---
; --- FUNCTION: endarchive ---
endarchive:
    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, code_buffer
    mov rdx, r14
    syscall
    
    cmp r14, CODE_LIMIT
    jae .write_data
    
    mov rax, 8
    mov rdi, [end_fd]
    mov rsi, CODE_LIMIT
    mov rdx, 0
    syscall

.write_data:
    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, data_buffer
    mov rdx, r15
    syscall

    mov rax, 3
    mov rdi, [fd]
    syscall
    mov rax, 3
    mov rdi, [end_fd]
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_lines_archive
    mov rdx, msg_lines_archive_len
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
