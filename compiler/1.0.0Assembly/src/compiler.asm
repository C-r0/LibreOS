bits 64

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
	hello: db "Welcome To Compiler!",10
	hellolen: equ $-hello
	compiling: db "Compiling: "
	compilinglen: equ $-compiling
	newline: db 10
	; COMMANDS
	; EXIT
	cmd_exit_str: db "exit"
	; EXEC
	cmd_exec_str: db "exec"
	; MOV
	cmd_mov_str: db "mov",0 
	cmd_mov_rax: db "rax",0
	cmd_mov_rdi: db "rdi",0
	cmd_mov_rsi: db "rsi",0
	cmd_mov_rdx: db "rdx",0
	; VARIABLES
	cmd_var_str: db "var",0
	var_memory_base: dq 0x600000

section .bss
	end_fd: resq 1
	fd: resq 1
	bytesnum: resq 1
	file: resb 1024
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
	je endarchive
	mov al, [file + rbx]

	; COMPARING

	cmp al, ' '
	je nextchar

	cmp al, 10
	je charnewline

	; CHARACTER
	xor rdi, rdi
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
	mov al,[file + rbx]
	cmp rbx, r12
	cmp al, '('
	je endcmd
	cmp al, ' '
	je endcmd
	cmp al, 10
	je errorline

	mov [token + rdi], al
	inc rdi
	inc rbx
	jmp haschar

; --- FUNCTION: endcmd ---
endcmd:
	mov byte [token + rdi], 0
	mov [token_len], rdi

	mov eax, [token]
	
	mov edx, [cmd_exit_str]
	cmp eax, edx
	je cmdexit

	mov edx, [cmd_exec_str]
	cmp eax, edx
	je cmdexec

	mov edx, [cmd_mov_str]
	cmp eax, edx
	je cmdmov

	mov edx, [cmd_var_str]
	cmp eax, edx
	je cmdvar

	jmp errorline

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
    inc rbx
    xor rdi, rdi

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
	cmp rbx, r12
	jge errorline
	inc rdi
	inc rbx
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

	jmp .second_arg_variable

.second_arg_variable_done:
	mov byte [cmd_arg_2 + rdi], 0
	mov [cmd_arg_2_len], rdi
	mov byte [is_addr], 1
	inc rbx
	inc rbx
	ret

.second_arg_done:
    mov byte [cmd_arg_2 + rdi], 0
    mov [cmd_arg_2_len], rdi
    mov byte [is_addr], 0
    inc rbx
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

	mov byte [codgen_buffer + 0], 0xB8 ; SYSCALL EXIT
	mov dword [codgen_buffer + 1], 60

	mov byte [codgen_buffer + 5], 0xBF ; 00 00 00 MOV EDI ARG
	mov dword [codgen_buffer + 6], eax

	mov word [codgen_buffer + 10], 0x050F

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 12
	syscall
	
	jmp cmpchar
; --- FUNCTION: cmdexit ---
; -------------------------
; --- FUNCTION: cmdexec ---
cmdexec:
	.clean_line:
        inc rbx
        cmp byte [file + rbx], 10
        jne .clean_line
	mov word [codgen_buffer + 0], 0x050F

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 2
	syscall

	jmp cmpchar
; --- FUNCTION: cmdexec ---
; -------------------------
; --- FUNCTION: cmdmov ---
cmdmov:
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

	mov [codgen_buffer + 2], eax

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 10
	syscall

	jmp cmpchar

.mov_rax_mem:
	mov byte [codgen_buffer + 0], 0x48
    mov byte [codgen_buffer + 1], 0x8B
    mov byte [codgen_buffer + 2], 0x04
    mov byte [codgen_buffer + 3], 0x25

    call var_to_addr

    mov [codgen_buffer + 4], eax

    mov rax, 1
    mov rdi, [end_fd]
    mov rsi, codgen_buffer
    mov rdx, 8
    syscall

cmdmov_rdi:
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBF

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 10
	syscall

	jmp cmpchar

cmdmov_rsi:
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBE

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 10
	syscall

	jmp cmpchar

cmdmov_rdx:
	mov byte [codgen_buffer + 0], 0x48
	mov byte [codgen_buffer + 1], 0xBA

	call atoi_arg_2

	mov [codgen_buffer + 2], eax

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 10
	syscall

	jmp cmpchar

cmdmov_al:
	mov byte [codgen_buffer + 0], 0xB0

	call atoi_arg_2

	mov [codgen_buffer + 1], eax

	mov rax, 1
	mov rdi, [end_fd]
	mov rsi, codgen_buffer
	mov rdx, 2
	syscall

	jmp cmpchar
; --- FUNCTION: cmdmov ---
; ------------------------
var_to_addr:
	mov eax, 0x600000
	ret
; -----------------------
; --- FUNCTION: cmdvar ---
cmdvar:
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
    je .after_name
    cmp al, '='
    je .after_name
    mov [var_name + rdi], al
    inc rdi
    inc rbx
    jmp .name_loop

.after_name:
    mov byte [var_name + rdi], 0
    mov [var_name_len], rdi

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

.done:
    mov byte [var_value + rdi], 0
    mov [var_value_len], rdi
    inc rbx
    
    jmp cmpchar
; --- FUNCTION: cmdvar ---
; --- FUNCTION: endarchive ---
endarchive:
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
