    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
      

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
    
     
    sys_exit     equ     60
    
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
    
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

    
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20
    bufferlen     equ   256


;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:	

   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

   push   ax

   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout 
   syscall

   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax 
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9	
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 


   sub    rsp, 1

   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall

   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx 
   cmp    bl, 0
   je     sEnd
   neg    rax 
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall 
    
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start 
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------




; rdi : file name; rsi : file permission
createFile:
    mov     rax, sys_create
    mov     rsi, sys_IRUSR | sys_IWUSR 
    syscall
    cmp     rax, -1   ; file descriptor in rax
    jle     createerror
    mov     rsi, suces_create           
    ;call    printString
    ret
createerror:
    mov     rsi, error_create
    ;call    printString
    ret

;----------------------------------------------------
; rdi : file name; rsi : file access mode 
; rdx: file permission, do not need
openFile:
    mov     rax, sys_open
    mov     rsi, O_RDWR     
    syscall
    cmp     rax, -1   ; file descriptor in rax
    jle     openerror
    mov     rsi, suces_open
    ;call    printString
    ret
openerror:
    mov     rsi, error_open
    ;call    printString
    ret
;----------------------------------------------------
; rdi point to file name
appendFile:
    mov     rax, sys_open
    mov     rsi, O_RDWR | O_APPEND
    syscall
    cmp     rax, -1     ; file descriptor in rax
    jle     appenderror
    mov     rsi, suces_append
    ;call    printString
    ret
appenderror:
    mov     rsi, error_append
    ;call    printString
    ret
;----------------------------------------------------
; rdi : file descriptor ; rsi : buffer ; rdx : length
writeFile:
    mov     rax, sys_write
    syscall
    cmp     rax, -1         ; number of written byte
    jle     writeerror
    mov     rsi, suces_write
    ;call    printString
    ret
writeerror:
    mov     rsi, error_write
    ;call    printString
    ret
;----------------------------------------------------
; rdi : file descriptor ; rsi : buffer ; rdx : length
readFile:
    mov     rax, sys_read
    syscall
    cmp     rax, -1           ; number of read byte
    jle     readerror
    mov     byte [rsi+rax], 0 ; add a  zero ??????????????
    push    rsi
    mov     rsi, suces_read
    ;call    printString
    pop     rsi
    ret
readerror:
    mov     rsi, error_read
    ;call    printString
    ret
;----------------------------------------------------
; rdi : file descriptor
closeFile:
    mov     rax, sys_close
    syscall
    cmp     rax, -1      ; 0 successful
    jle     closeerror
    mov     rsi, suces_close
    ;call    printString
    ret
closeerror:
    mov     rsi, error_close
    ;call    printString
    ret

;----------------------------------------------------
; rdi : file name
deleteFile:
    mov     rax, sys_unlink
    syscall
    cmp     rax, -1      ; 0 successful
    jle     deleterror
    mov     rsi, suces_delete
    call    printString
    ret
deleterror:
    mov     rsi, error_delete
    call    printString
    ret
;----------------------------------------------------
; rdi : file descriptor ; rsi: offset ; rdx : whence
seekFile:
    mov     rax, sys_lseek
    syscall
    cmp     rax, -1
    jle     seekerror
    mov     rsi, suces_seek
    call    printString
    ret
seekerror:
    mov     rsi, error_seek
    call    printString
    ret

;----------------------------------------------------





strEndWith:
    enter 0,0 
    push rbx 
    push rdi
    push rsi 
    push r11 

    mov r10, qword [rbp + 16]
    mov r12, qword [rbp + 24]

    mov rdi, r10
    call GetStrlen
    mov rsi , rdx

    mov rdi, r12
    call GetStrlen
    mov rdi, rdx 

    cmp rsi, rdi 
    jle strEndWithEnd

    add r12, rdi 
    dec r12 
    add r10, rsi 
    dec r10

    mov rax, qword [zero]
    mov rcx, rdi
    strEndWithloopstart:
        mov bl, byte [r12]
        cmp byte [r10], bl
        jne strEndWithEnd
        dec r12 
        dec r10
        loop strEndWithloopstart    
    mov rax, qword [one]

    strEndWithEnd:
    pop r11 
    pop rsi 
    pop rdi 
    pop rbx 
    leave
ret 16

open_directory:
    push rax
    push rdi 
    push rsi 
    push rdx 


    mov rax, sys_open            ; sys_open
    mov rdi, dir_path       ; Directory path
    mov rsi, 0              ; O_RDONLY
    xor rdx, rdx            ; Mode is zero
    syscall

    mov rsi, rax 

    read_entries:
        mov rax, 217           ; sys_getdents64
        mov rdi, rsi           ; File descriptor
        mov rsi, buf           ; Buffer to store directory entries
        mov rdx, buf_size      ; Buffer size
        syscall

    ; Check if end of directory
    cmp rax, 0
    je close_directory

    ; Loop through the directory entries
    xor rdi, rdi ; starting offset for reading directory entries
    mov rsi, buf 
    mov r15, file_name

    loop_entries:
        ; Read the   field
        mov rax, qword [rsi]
        cmp rax, 0
        je close_directory

        add rsi, 16
        xor rax, rax 
        mov ax, word [rsi]
        mov bx, ax 
        sub rsi, 16

        add rsi,19 ; offset to d_name field
        xor rax, rax 
        push endTxt
        push rsi 
        call strEndWith
        cmp rax, 1
        jne nottxt

        mov rdi, rsi 
        call GetStrlen
        mov rcx, rdx 
        push rsi 
        copyloop:
            mov dl, byte[rsi]
            mov byte [r15], dl
            inc r15
            inc rsi
            loop copyloop
        mov byte [r15], 0
        inc r15
        pop rsi
        
        nottxt:
            sub rsi, 19
            add rsi, rbx
            jmp loop_entries

    close_directory:
        
        mov rax, 3
        mov rdi, rsi ; directory file descriptor
        syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax 
ret 

printFileContext:
    enter 0,0
    push rax 
    push rdi 
    push rsi 
    push rdx 

    mov r10, qword [rbp + 16]

    mov rdi, r10 
    call openFile
    mov [FD], rax 
    
    mov rdi, [FD]
    mov rsi, buf
    mov rdx, buf_size 
    call readFile
    mov rdi, rsi 
    mov qword [file_pointer], rsi 
    ;call printString
    ;call newLine
    mov rdi, [FD]
    call closeFile 

    pop rdx 
    pop rsi 
    pop rdi
    pop rax 
    leave
ret 8

buildLocalPath:
    enter 0,0 
    push rax
    push rbx 
    push rcx 
    push rsi 
    push rdi 
    push rdx 

    mov r12, qword [rbp + 16]

    mov r14, files_path

    mov r13, files_path_original
    mov rdi, r13 
    call GetStrlen
    mov rcx, rdx  
    
    buildLocalPathCopyLoop:
        mov dl, byte [r13] 
        mov byte [r14], dl 
        inc r13 
        inc r14 
        loop buildLocalPathCopyLoop
    mov byte [r14], 0    

    mov r10, files_path
    mov rdi, r10 
    call GetStrlen
    add r10, rdx 
 

    mov rdi, r12
    call GetStrlen
    mov rcx, rdx 

    buildLocalPathloop:
        mov dl, byte [r12]
        mov byte [r10], dl 
        inc r10 
        inc r12
        loop buildLocalPathloop  
    mov byte [r10], 0
    ;mov rsi, files_path
   

    pop rdx 
    pop rdi
    pop rsi 
    pop rcx 
    pop rbx 
    pop rax 
    leave 
ret 8

; searchWrod:
;     enter 0,0
;     push rax
;     push rbx 
;     push rcx 
;     push rdi 
;     push rsi 
;     push rdx 

;     mov r10,qword [rbp+16]
;     mov r12,qword [rbp+24]
;     mov rdi, r12 
;     call GetStrlen
;     mov r13, rdx 

;     mov r15, 0
;     mov r14, 0
;     searchWordOuterLoop:
;         xor rdx, rdx 
;         mov r12, qword [rbp+24]
;         mov dl, byte [r10]
;         cmp byte [r12], dl 
;         je prefoundLoop
;         inc r10 
;         cmp byte [r10], 0
;         je searchWordOuterLoopFinish
;         jmp searchWordOuterLoop
;         prefoundLoop:
;             mov rcx, r13
;             mov r14, 0
;         foundLoop:
;             mov dl, byte [r10+r14]
;             cmp byte [r12+r14], dl
;             jne foundfail
;             inc r14 
;             loop foundLoop
;         inc r15 
;         foundfail:
;             inc r10 
;             cmp byte [r10], 0
;             je searchWordOuterLoopFinish

;         jmp searchWordOuterLoop 
; searchWordOuterLoopFinish:


;     pop rdx 
;     pop rsi 
;     pop rdi 
;     pop rcx 
;     pop rbx 
;     pop rax 
;     leave
; ret 16

readLine: 
    readLineloop:
        call getc 
        cmp al, NL 
        je endreadline
        mov byte [rsi], al 
        inc rsi 
        jmp readLineloop
    endreadline:
        mov byte [rsi], 0
ret 
readLineForAppend: 
    readLineloopAppend:
        call getc 
        cmp al, '#'
        je endreadlineAppend
        mov byte [rsi], al 
        inc rsi 
        jmp readLineloopAppend
    endreadlineAppend:
        mov byte [rsi], 0
ret

copyFolderPath:
    push rax 
    push rbx 
    push rsi 
    push rdx 
    push rcx 


    mov rsi, dir_path 
    mov rdi, rsi
    call GetStrlen
    mov rcx, rdx 
    mov rdi, files_path_original
    copyFolderPathLoop:
        mov dl , byte [rsi]
        mov byte [rdi], dl
        inc rdi 
        inc rsi 
    loop copyFolderPathLoop
    mov byte [rdi], 0
    
    mov rsi, dir_path
    mov rdi, rsi
    call GetStrlen
    mov rcx, rdx 
    mov rdi, files_path
    copyFolderPathLoop2:
        mov dl, byte [rsi]
        mov byte [rdi], dl
        inc rdi 
        inc rsi 
    loop copyFolderPathLoop2
    mov byte [rdi], 0
    
    pop rcx 
    pop rdx 
    pop rsi 
    pop rbx 
    pop rax 
ret 

stringComparisson:
    enter 0,0 
    push rax 
    push rbx
    push rcx
    push rsi
    push rdx 
    push r10 
    push r11 
    push r12 
    push r13 
    push r14 


    mov r10, qword [rbp + 16]
    mov r12, qword [rbp + 24]
    mov rsi, r12 
    stringComparissonloop:
        cmp byte [r12], '.'
        je keepTheOrder
        cmp byte [r10], '.'
        je changeTheOrder
        mov dl, byte [r10]
        cmp byte [r12], dl
        jg changeTheOrder
        jl keepTheOrder
        inc r12 
        inc r10 
        jmp stringComparissonloop
    changeTheOrder:
        mov r15, 1
        jmp stringComparissonEnd
    keepTheOrder:
        mov r15, 0
    stringComparissonEnd:

    pop r14 
    pop r13 
    pop r12 
    pop r11 
    pop r10
    pop rdx 
    pop rsi 
    pop rcx 
    pop rbx 
    pop rax 
    leave
ret 16
sortFileNameList:
    push rax 
    push rbx
    push rcx
    push rsi
    push rdx 
    push r10 
    push r12 
    push r14 
    push r15

    mov rbx, arrayaddress
    mov rsi, file_name

    xor rcx, rcx  
    startsizeLoop:
        mov rdx, rsi 
        mov [rbx], rdx 
        inc rcx 
        mov rdi, rsi
        call GetStrlen
        add rsi, rdx 
        inc rsi 
        add rbx, 8
        cmp byte [rsi], 0
        jne startsizeLoop
    mov rsi, arrayaddress
    mov r10, rcx
    mainloop:
        mov rax, [rsi]
        ;call writeNum
        ;call newLine
        add rsi, 8
        loop mainloop
    mov r12, 0
    dec r10 
    dec r10
    mov rsi, arrayaddress
    outerloop:
        mov r13, 0 
        innerloop:
            mov r14, r13 
            inc r14  
            mov rax, qword [rsi+r13*8]
            mov rbx, qword [rsi+r14*8]
            push rax 
            push rbx 
            call stringComparisson
            cmp r15, 1
            je swap 
            jmp endofswap
            swap:
                mov qword [rsi+r13*8], rbx
                mov qword [rsi+r14*8], rax 
            endofswap:
         
            inc r13
            cmp r13, r10 
            jle innerloop
    inc r12 
    cmp r12, r10 
    jle outerloop

    ;call newLine

    add r10, 2
    mov rcx, r10 
    mov r12, sortedarray
    mov rsi, arrayaddress
    mainloop2:
        mov rax, [rsi]
        push rsi 
        mov rsi, rax 

        
        pop rsi 
        mov rdi, rax         
        call GetStrlen
        push rcx 
        mov rcx, rdx 
      
        mainloop2second:
            mov dl, byte [rax]
            mov byte [r12], dl 
            inc r12 
            inc rax 
            loop mainloop2second
        pop rcx 
        mov byte [r12], 0
        inc r12 
        
        add rsi, 8
        loop mainloop2

    mov byte [r12], 0
    
    pop r15 
    pop r14 
    pop r12 
    pop r10 
    pop rdx 
    pop rsi 
    pop rcx 
    pop rbx 
    pop rax 
ret

numTostring:
   push   rax
   push   rcx
   push   rdx
   push   rsi 
    mov rsi, finalResult

  
    mov rdi, rsi 
    call GetStrlen
    add rsi, rdx 
    
   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain2
   push   rax 
   mov    al, '-'
   ;call   putc
   mov byte [rsi], al 
   inc rsi 
   pop    rax
   neg    rax  

    wAgain2:
   cmp    rax, 9	
   jle    cEnd2
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain2

    cEnd2:
   add    al, 0x30
   ;call   putc
   mov byte [rsi], al 
   inc rsi 
   dec    rcx
   jl     wEnd2
   pop    rax
   jmp    cEnd2
    wEnd2:
    mov byte [rsi], NL 
    inc rsi 
    mov rbx, rsi 
   pop    rsi 
   pop    rdx
   pop    rcx
   pop    rax
   
ret


display:
    enter 0,0
    push rax 
    push rdi 
    push rsi 
    push rdx 
    push r10 
    push r12 

    mov r10, qword [rbp + 16]

    mov rdi, r10 
    call openFile
    mov [FD], rax 
    
    mov rdi, [FD]
    mov rsi, buf
    mov rdx, buf_size 
    call readFile
    mov rdi, rsi 
    mov qword [file_pointer], rsi 
    ; call printString
    ; call newLine
    mov rdi, [FD]
    call closeFile 
    
    mov rsi, qword [file_pointer] 
    mov r10, pointer_to_the_file_string
    mov r12, 0
    copyfilestring:
        mov dl, byte [rsi + r12]
        cmp dl, 0 
        je finishcopyfilestring
        mov byte [r10 + r12], dl
        inc r12
        jmp copyfilestring

    finishcopyfilestring:
        dec r12 
        ; mov al, byte [r10 + r12 ]
        ; call writeNum
        ; call newLine
        cmp byte [r10 + r12], 107
        je displayhere
        mov byte [r10 + r12], dl 
        displayhere:

    mov rsi, pointer_to_the_file_string
    call printString
    call newLine

    pop r12 
    pop r10 
    pop rdx 
    pop rsi 
    pop rdi
    pop rax 
    leave
ret 8

report:
    push rax 
    push rdi 
    push rsi 
    push rdx 
    push rbx 
    push rcx 
    push r8
    push r9
    push r10 
    push r12 


    mov r10, pointer_to_the_file_string
    mov rsi, r10 
  
    mov qword [file_pointer], rsi 

    mov r9, rsi 
    mov qword [num_char], 0 
    mov qword [num_line], 0 
    mov qword [num_word], 0
    start_char_count:
        cmp byte [rsi], 0 
        je finish_char_count 
        inc qword [num_char]
        inc rsi
        jmp start_char_count
    finish_char_count:
        mov rsi, r9
        mov qword [word_flag], 0 

    start_word_count:
        cmp byte [rsi], 0 
        je finish_word_count
        cmp byte [rsi], ' '
        je space_label
        cmp byte [rsi], 10
        je space_label
        cmp qword [word_flag], 0
        je not_space_word 
        jmp next_char
    not_space_word:
        inc qword [num_word]
        mov qword [word_flag], 1
        jmp next_char
    space_label:
        mov qword [word_flag], 0 
        jmp next_char
    next_char:
    inc rsi 
    jmp start_word_count
    finish_word_count:
        mov rsi, r9 

    start_line_count:
        cmp byte [rsi], 0 
        je finish_line_count
        cmp byte [rsi], 10 
        jne line_count_next_char
        inc qword [num_line]
        line_count_next_char:
        inc rsi 
        jmp start_line_count
    finish_line_count:
        inc qword [num_line]
        mov rsi, r9 
        mov rax, qword [num_char]
        call writeNum
        call newLine
        mov rax, qword [num_word]
        call writeNum
        call newLine
        mov rax, qword [num_line]
        call writeNum
        call newLine


    pop r12 
    pop r10 
    pop r9 
    pop r8 
    pop rcx 
    pop rbx 
    pop rdx 
    pop rsi 
    pop rdi
    pop rax 
ret 


searchWrodindex:
    enter 0,0
    push rax
    push rbx 
    push rcx 
    push rdi 
    push rsi 
    push rdx 
    push rdi 
    push r10 
    push r12 
    push r9 

    mov r10, pointer_to_the_file_string
    mov rsi, r10 
    call printString
    call newLine
    mov r9, r10
    mov r12,qword [rbp+16]
    mov rdi, r12 
    call GetStrlen
    mov r13, rdx 

    mov r15, 0
    mov r14, 0
    searchWordOuterLoop:
        xor rdx, rdx 
        mov r12, qword [rbp+16]
        mov dl, byte [r10]
        cmp byte [r12], dl 
        je prefoundLoop
        inc r10 
        cmp byte [r10], 0
        je searchWordOuterLoopFinish
        jmp searchWordOuterLoop
        prefoundLoop: 
            mov rcx, r13
            mov r14, 0
        foundLoop:
            mov dl, byte [r10+r14]
            cmp byte [r12+r14], dl
            jne foundfail
            inc r14 
            loop foundLoop
        inc r15 
        push rax 
        mov rax, r10 
        sub rax, r9 
        call writeNum
        call newLine
        pop rax 
        foundfail:
            inc r10 
            cmp byte [r10], 0
            je searchWordOuterLoopFinish

        jmp searchWordOuterLoop 
    searchWordOuterLoopFinish:


    pop r9 
    pop r12 
    pop r10 
    pop rdi 
    pop rdx 
    pop rsi 
    pop rdi 
    pop rcx 
    pop rbx 
    pop rax 
    leave
ret 

searchandreplace:
    enter 0,0
    push rax
    push rbx 
    push rcx 
    push rdi 
    push rsi 
    push rdx 
    push r8 
    push r9 
    push r10 
    push r12 
    push r13 
    push r14 

    xor rsi, rsi 
    xor rax, rax 
    xor rcx, rcx 
    xor r10, r10 
    xor r12, r12 
    xor r15, r15 
    xor r14, r14 

    mov r10, pointer_to_the_file_string
    mov rsi, 0
    mov rbx , r10 
    mov r12,qword [rbp+16]   ; index  
 
    
    mov r13, replaced_string
    mov r14, 0
    mov rcx, r12
    copy_replace_loop_start:
        mov dl, byte [r10 + r14]
        mov byte [r13 + r14], dl 
        inc r14
        loop copy_replace_loop_start
        
        add r13, r14
        add r10, r14 
        add rsi, r14
        mov rdi, keyword_for_replace 
        call GetStrlen
        add r10, rdx 
        add rsi, rdx 

        mov rdi, r10 
        call GetStrlen
        mov r15, rdx
    
        
        mov rdi, replace_keyword 
        call GetStrlen
        mov rcx , rdx
        mov rdi ,replace_keyword


        mov r9, 0 
        replace_loop_start1: 
            mov dl, byte [rdi + r9] 
            mov byte [r13 + r9], dl 
            inc r9 
            loop replace_loop_start1
            add r13, r9 

        


      
    mov r10, pointer_to_the_file_string
    add r10, rsi   


    mov rcx, r15 
    mov r9 , 0
    replace_end_start:
        mov dl, byte [r10 + r9] 
        mov byte [r13 + r9], dl 
        inc r9 
        loop replace_end_start

    endofreplacesearch:
        mov byte [r13 + r9], 0 
        mov rsi, replaced_string
        call printString
        call newLine

        ;mov pointer_to_the_file_string, rsi 
        mov qword [file_pointer], rsi 
    mov r10, replaced_string
    mov r12, pointer_to_the_file_string
    mov r13, 0 
    copyforsearchandreplace:
        mov dl, byte [r10 + r13]
        cmp dl, 0 
        je finishcopyforsearchandreplace
        mov byte [r12 + r13], dl 
        inc r13
        jmp copyforsearchandreplace
        
    finishcopyforsearchandreplace:
        mov byte [r12 + r13], dl 
    pop r14
    pop r13
    pop r12 
    pop r10 
    pop r9 
    pop r8 
    pop rdx 
    pop rsi 
    pop rdi 
    pop rcx 
    pop rbx 
    pop rax 
    leave
ret 8

appendtothefile:
    push rax
    push rbx 
    push rcx 
    push rdx
    push rdi 
    push rsi 
    push r10 
    push r12 
    push r13 

    mov rsi, appendanswer
    call readLineForAppend
    mov r10, appendanswer
    mov r12, pointer_to_the_file_string

    appendstart:
        mov dl, byte [r12]
        cmp dl, 0 
        je finishappendstart
        inc r12 
        jmp appendstart
    finishappendstart:

        mov r13, 0 
        
    appendingstart:
        mov dl, byte [r10 + r13] 
        cmp dl, '0'
        je appedingfinish
        mov byte [r12 + r13], dl 
        inc r13 
        jmp appendingstart
    appedingfinish:
        mov byte [r12 + r13], 0

    mov rsi, pointer_to_the_file_string
    call printString


    pop r13 
    pop r12 
    pop r10 
    pop rsi 
    pop rdi 
    pop rdx 
    pop rcx 
    pop rbx 
    pop rax 
ret 
deletfromendothefile:
    push rax
    push rbx 
    push rcx 
    push rdx
    push rdi 
    push rsi 
    push r10 
    push r12 
    push r13 

    call readNum
    mov r10, rax 
    inc r10 
    mov r12, pointer_to_the_file_string
    deleteendofthestringstart:
        cmp byte [r12], 0 
        je deleteendofthestringfinish
        inc r12 
        jmp deleteendofthestringstart
    deleteendofthestringfinish:
        dec r12 
        mov rcx, r10 
        deletionstart:
            mov byte [r12], 0 
            dec r12 
            loop deletionstart
    mov rsi, pointer_to_the_file_string
    call printString
    call newLine 

    pop r13 
    pop r12 
    pop r10 
    pop rsi 
    pop rdi 
    pop rdx 
    pop rcx 
    pop rbx 
    pop rax 
ret 

saveas:
    push rax
    push rbx 
    push rcx 
    push rdx
    push rdi 
    push rsi 
    push r10 
    push r12 
    push r13


    mov rsi, saveasrequest
    call printString
    mov rsi, saveasfilepath
    call readLine 
    mov rdi, saveasfilepath
    call openFile
    mov [FD], rax
    cmp rax, -1 
    jg saveaserror
    
    mov rdi, saveasfilepath
    call createFile
    mov [appendFD], rax 

    mov rdi, pointer_to_the_file_string
    call GetStrlen
    mov rdi, [appendFD]
    mov rsi, pointer_to_the_file_string

    call writeFile

    mov rdi, [appendFD]
    call closeFile
    jmp finishsaveas

    saveaserror:
        mov rsi, saveaserrormassage
        call printString
        call newLine
finishsaveas:
    pop r13 
    pop r12 
    pop r10 
    pop rsi 
    pop rdi 
    pop rdx 
    pop rcx 
    pop rbx 
    pop rax 
ret 


section .data
    fileName    db    "/home/arman/Desktop/AssMiniProject/testFolder/input.txt", 0
    FD          dq    0
    appendFD    dq    0
    
    error_create        db      "error in creating file             ", NL, 0
    error_close         db      "error in closing file              ", NL, 0
    error_write         db      "error in writing file              ", NL, 0
    error_open          db      "error in opening file              ", NL, 0
    error_open_dir      db      "error in opening dir               ", NL, 0
    error_append        db      "error in appending file            ", NL, 0
    error_delete        db      "error in deleting file             ", NL, 0
    error_read          db      "error in reading file              ", NL, 0
    error_print         db      "error in printing file             ", NL, 0
    error_seek          db      "error in seeking file              ", NL, 0
    error_create_dir    db      "error in creating directory        ", NL, 0
    suces_create        db      "file created and opened for R/W    ", NL, 0
    suces_create_dir    db      "dir created and opened for R/W     ", NL, 0
    suces_close         db      "file closed                        ", NL, 0
    suces_write         db      "written to file                    ", NL, 0
    suces_open          db      "file opend for R/W                 ", NL, 0
    suces_open_dir      db      "dir opened for R/W                 ", NL, 0
    suces_append        db      "file opened for appending          ", NL, 0
    suces_delete        db      "file deleted                       ", NL, 0
    suces_read          db      "reading file                       ", NL, 0
    suces_seek          db      "seeking file                       ", NL, 0
    
    buf_size    equ 99999   ; Buffer size for directory entries
    
    zero            dq    0
    one             dq    1
    two             dq    2
    three           dq    3
    four            dq    4
    five            dq    5 
    six             dq    6 
    seven           dq    7
    eight           dq    8
    nine            dq    9
    num_word        dq    0
    num_char        dq    0
    num_line        dq    0
    word_flag       dq    0
    endTxt          db    ".txt", 0
    testtxt         db    "arman.txt", 0
    file_pointer    dq    0

    resultfilename  db    "result.txt", 0  
    
    help            db    "Please select one of the following options?", 10,"1. Display the content of a file", 10, "2. Report", 10, "3. Search", 10, "4. Search and replace", 10, "5. Append", 10, "6. Delete", 10, "7. Save", 10, "8. Save as", 10, "9. Exit ", 10,0  
    onecommand      db    "Enter the file path: ", 0
    threecommandhelper  db "Enter the keyword: ", 0 
    fourcommandhelper   db "Enter the index from the list above: ", 0
    fourcommandhelper2  db "Enter the word you want to replace: ", 0
    report_characters    db    "Number of chars: ", 0
    report_words         db    "Number of words: ", 0
    report_lines         db    "Number of lines: ", 0
    appendrequest        db     "Enter the text to append: ", 0
    saveasrequest       db  "Enter the file path: ", 0
    notValidInput       db     "please enter a valid input!", 10 , 0
    saveaserrormassage  db   "ERROR: This file already exits", 10 , 0  

section .bss
    buf                 resb buf_size 
    file_name           resb 99999999
    keyword             resb 9999999
    replace_keyword     resb 9999999
    arrayaddress        resq 9999999
    sortedarray         resb 9999999
    finalResult         resb 9999999
    dir_path            resb 9999999
    files_path_original resb 9999999
    files_path          resb 9999999
    display_input       resb 9999999
    replaced_string     resb 9999999
    keyword_for_replace resb 9999999
    file_address        resb 9999999
    pointer_to_the_file_string resb 99999999
    appendanswer        resb 99999999
    saveasfilepath      resb 99999999

    
section .text
    global _start

_start:
    mov rsi, help 
    call printString
    xor rsi, rsi 
    call readNum

    cmp rax, [one]
    je display_call
    
    cmp rax, [two]
    je report_call

    cmp rax, [three]
    je searchindex_call 

    cmp rax, [four] 
    je searhandreplace_call 

    cmp rax, [five]
    je append_call 

    cmp rax, [six]
    je delete_call

    cmp rax, [seven]
    je savethefile

    cmp rax, [eight]
    je saveas

    cmp rax, [nine]
    je Exit

    mov rsi, notValidInput
    call printString
    call newLine
    jmp _start
display_call:
    mov rsi, onecommand
    call printString
    mov rsi, file_address
    call readLine
    push file_address 
    call display 
    jmp _start

report_call:
    call report 
    jmp _start

searchindex_call:
    mov rsi, threecommandhelper
    call printString
    mov rsi, keyword
    call readLine
    push keyword
    call searchWrodindex 
    mov rax, r15 
    call writeNum
    call newLine
    jmp _start

searhandreplace_call:
    xor rsi, rsi 
    mov rsi, threecommandhelper
    call printString
    mov rsi, keyword_for_replace 
    call readLine
    mov rsi, fourcommandhelper2
    call printString
    mov rsi, replace_keyword
    call readLine

    push keyword_for_replace
    call searchWrodindex

    mov rsi, fourcommandhelper
    ;call printString
    call readNum
    push rax 
    call searchandreplace
    
    mov rsi, qword [file_pointer] 
    call printString
    call newLine
    jmp _start

append_call:
    mov rsi, appendrequest
    call printString
    call appendtothefile 
    jmp _start 

delete_call:
    call deletfromendothefile
    jmp _start
savethefile: 
    mov rdi, file_address
    call openFile
    mov [FD], rax   
    mov rdi, pointer_to_the_file_string
    call GetStrlen
    mov rdi, [FD]
    mov rsi, pointer_to_the_file_string
    call writeFile
    mov rdi, [FD]
    call closeFile 
    jmp _start





    ; mov rdi, resultfilename
    ; call createFile
    ; mov [appendFD], rax 
    
    mov rsi, dir_path
    call readLine
    call copyFolderPath
    mov rsi, keyword
    call readLine

    call open_directory

    mov rbx, finalResult 
    call sortFileNameList
    mov rsi, sortedarray
    printloop:
        push rsi 
        mov rdi, rsi 
        call GetStrlen
        mov rcx, rdx 
        finalresultloop:
            mov dl ,byte [rsi]
            mov byte [rbx], dl 
            inc rbx 
            inc rsi 
            loop finalresultloop
        pop rsi 

        mov byte [rbx], ' ' ;put a space between filename and number of occurence 
        inc rbx 
        mov byte [rbx], 0

        ;push rsi 
        ;call buildLocalPath
        ;push files_path
        ;call printFileContext   ;make file_pointer points to the content of the file 
        ;push keyword
        ;push qword [file_pointer]
        ;call searchWrod
        ;mov rax , r15 
        ;call numTostring

        mov rdi, rsi 
        call GetStrlen
        add rsi, rdx 
        inc rsi 
        cmp byte [rsi], 0 
        jne printloop
    
    mov byte [rbx], 0 
    
    ; mov rdi, finalResult
    ; call GetStrlen
    ; mov rdi, [appendFD]
    ; mov rsi, finalResult

    ;call writeFile

    ;mov rdi, [appendFD]
    ;call closeFile
        
Exit:
    call newLine
    mov     rax,    sys_exit
    xor     rdi,    rdi
    syscall
