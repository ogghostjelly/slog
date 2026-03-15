    global _start

    section .text

_start:
    lea rax, [_start_n0] ; return address
    mov rbx, 32          ; amount to allocate
    jmp alloc
_start_n0:
    lea rax, [_start_n1]
    jmp pop
_start_n1:
    lea rax, [_start_n2] ; return address
    mov rbx, 32          ; amount to allocate
    jmp alloc
_start_n2:
    mov qword [rsp+8], 0x1
    mov qword [rsp+16], 0x2
    mov qword [rsp+24], 0x3
    mov qword [rsp+32], 0x4
    mov rdi, rsp ; keep for later

    ; allocate some garbage data to test out resize
    lea rax, [_start_n3] ; return address
    mov rbx, 32          ; amount to allocate
    jmp alloc
_start_n3:
    mov qword [rsp+8], 0x6
    mov qword [rsp+16], 0x7
    mov qword [rsp+24], 0x8
    mov qword [rsp+32], 0x5
    
    lea rax, [_start_n4] ; return address
    mov rbx, rdi         ; ptr to
    mov rcx, 8           ; amount to resize
    
    mov rdi, 0x1
    mov rsi, 0x2
    mov rdx, 0x3

    jmp resize
_start_n4:
    lea rax, [_start_n5] ; return address
    mov rbx, 0           ; index
    jmp idx2addr
_start_n5:
    ; Exit the program
    mov eax, 1
    mov ebx, 0
    int 0x80

; Allocate a chunk of memory on the stack.
; 
; reg(rax) = ret
; reg(rbx) = size
alloc:
    ; allocate size bytes
    sub rsp, rbx
    ; set the last 8 bytes to size
    sub rsp, 8
    mov qword [rsp], rbx
    ; jump back to the caller
    jmp rax

; Pop a chunk of memory from the stack.
; 
; reg(rax) = ret
pop:
    add rsp, [rsp]
    add rsp, 8
    jmp rax

; Resize a chunk of memory on the stack.
; The code steps through the memory in chunks of 8, ensure pointers are 8-byte aligned!
; 
; reg(rax) = ret
; reg(rbx) = ptr
; reg(rcx) = size
resize:
    ; usually we can't use stack allocating functions,
    ; but as long as we return the stack back to a valid state it's all OK
    push rdx
    push rsi
    push rdi

    mov rdx, rsp
    sub rsp, rcx
resize_loop_condition:
    cmp rdx, rbx
    jl resize_loop_body

    ; set the last 8-bytes of the chunk to the new size
    ; calculate the new size
    mov rsi, [rbx]
    add rsi, rcx
    ; calculate the location of the new size
    mov rdi, rbx
    sub rdi, rcx
    ; set new size
    mov [rdi], rsi
    mov qword [rbx], 0

    pop rdi
    pop rsi
    pop rdx
    jmp rax
resize_loop_body:
    ; get the source data
    mov rsi, [rdx]
    mov qword [rdx], 0

    ; get destination address
    mov rdi, rdx
    sub rdi, rcx

    ; move the source data to the destination
    mov [rdi], rsi

    ; increment the pointer
    add rdx, 8
    jmp resize_loop_condition

    jmp xyz\xyz

xyz\xyz:
    

; Convert an index on the stack to an address
;
; reg(rax) = ret
; reg(rbx) = index
;
; reg(rcx) = return value
idx2addr:
    push rdx

    ; steps = length - index - 1
    sub rdx, rbx
    sub rdx, 1

    ; ptr = rsp
    ; we need to account for the rdx variable we pushed onto the stack
    ; so we need to add 8 to move rsp back.
    mov rcx, rsp
    add rcx, 8
idx2addr_loop_condition:
    cmp rdx, 0
    jne idx2addr_loop_body

    pop rdx
    jmp rax
idx2addr_loop_body:
    ; move back one step
    ; ptr -= size - 8
    add rcx, [rcx]
    add rcx, 8
    ; steps -= 1
    sub rdx, 1
    jmp idx2addr_loop_condition