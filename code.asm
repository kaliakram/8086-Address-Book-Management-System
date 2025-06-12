;Kouah_Ali_Akram_G02
;+==============================================================================+
;| _________  ________        ________       ___    ___ ________    _______     |
;||\___   ___\\   __  \      |\   ____\     |\  \  /  /|\   ____\  /  ___  \    |
;|\|___ \  \_\ \  \|\  \     \ \  \___|_    \ \  \/  / | \  \___|_/__/|_/  /|   |
;|     \ \  \ \ \   ____\     \ \_____  \    \ \    / / \ \_____  \__|//  / /   |
;|      \ \  \ \ \  \___|      \|____|\  \    \/  /  /   \|____|\  \  /  /_/__  |
;|       \ \__\ \ \__\           ____\_\  \ __/  / /       ____\_\  \|\________\|
;|        \|__|  \|__|          |\_________\\___/ /       |\_________\\|_______||
;|                              \|_________\|___|/        \|_________|          |
;+==============================================================================+      
;{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
;{}   ___                                _         _   _                         {}
;{}  / __\_   _    /\ /\___  _   _  __ _| |__     /_\ | | ___ __ __ _ _ __ ___   {}
;{} /__\// | | |  / //_/ _ \| | | |/ _` | '_ \   //_\\| |/ / '__/ _` | '_ ` _ \  {}
;{}/ \/  \ |_| | / __ \ (_) | |_| | (_| | | | | /  _  \   <| | | (_| | | | | | | {}
;{}\_____/\__, | \/  \/\___/ \__,_|\__,_|_| |_| \_/ \_/_|\_\_|  \__,_|_| |_| |_| {}
;{}       |___/                                                                  {}
;{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
data segment
    pkey db "press any key...$" 
    header db "Address Book Managment System:$" 
    choices db "please choose one of the following functions:",0Dh,0Ah
            db "1-Add a contact",0Dh,0Ah
            db "2-View all contacts",0Dh,0Ah
            db "3-Search a contact",0Dh,0Ah
            db "4-Modify a contact",0Dh,0Ah
            db "5-Delete a contact",0Dh,0Ah 
            db "6-Exit",0Dh,0Ah
            db "please enter your choice:$"
    valid db "please enter a valid choice$" 
    quitmsg db "see you next time!$"
    contacts db 16 dup("zzzzzzzzzz$","0000000000$",0)  ;11 byte for the number and the name(the eleventh one for the $ if the number/name is full) and 1 byte for the existance of the contact(logical delete:1exist,0not)
    buffer db 11 
           db ?  ;buffer to store the name/phone from the standard input, also used as an intermediate memory to exchange memory content
           db 11 dup(?) 
    contacts_number db 0 ;for the number of the current contacts(if 0 we cant delete,if 16 we cant add)   
    entername db "please enter the name:$"
    enternumber db "please enter the number:$"     
    full db "the contacts are full,you cannot add any contact!$"
    empty db "there is no contacts to show/delete/modify!$"      
    endcontact db "---------------------------$" 
    notfoundcontact db "this contact doesnt exist!$"  
    compare db 0h   
    names db "name:$"
    number db "number:$"  
    swapped db 0     
    loading db "Loading the contacts...$"
    
                
    
ends

stack segment
    dw   128  dup(0)
ends

code segment
start: ;initializing segment registers 
    mov ax,stack
    mov ss,ax
    mov ax, data
    mov ds, ax
    mov es, ax        
    
    call init_contacts
menu:lea dx,header
    call printstring  
    call newline
    lea dx,choices
    call printstring
    mov ah,1
    int 21h 
    mov cl,al
    call newline
;choices if..elseif..else for the menu
    cmp cl,'1'
    jne else1
    call clearscreen
    call add_a_contact
    jmp next
else1:cmp cl,'2'
    jne else2 
    call clearscreen
    call view_all_contacts
    jmp next
else2:cmp cl,'3'
    jne else3       
    call clearscreen
    call search_a_contact
    jmp next
else3:cmp cl,'4'
    jne else4       
    call clearscreen
    call modify_a_contact
    jmp next
else4:cmp cl,'5'
    jne else5       
    call clearscreen
    call delete_a_contact
    jmp next
else5:cmp cl,'6'
    jne els         
    call clearscreen
    lea dx,quitmsg
    call printstring
    jmp exit
els:
    lea dx,valid
    call printstring
next:            
    call newline
    call waitchar
    call newline 
    call clearscreen
    jmp menu
   
    ;terminating the program
exit:mov ax, 4c00h
    int 21h    
    ;procedures
    ;-------------------------
    waitchar proc
    ;role: waits for a character from the standard input 
        lea dx, pkey
        mov ah, 9
        int 21h   
        mov ah, 1
        int 21h 
        ret
    waitchar endp 
    ;-------------------------  
    newline proc
    ;role:prints a new line
        mov ah,2
        mov dl,0Dh
        int 21h
        mov ah,2
        mov dl,0Ah
        int 21h
        ret
    newline endp 
    ;-------------------------
    init_contacts proc
    ;role: sets last byte of names/phones to $ as a terminator to avoid getting to a wrong memory location when searching for names 
        push si
        mov cx,16
        lea si,contacts
        initt:
        mov byte ptr[si+10],'$'
        mov byte ptr[si+21],'$'
        add si,23
        loop initt
        pop si
        ret
    init_contacts endp
    ;-------------------------
    compare_strings proc 
    ;role:compare the ascii values of two strings,return the result to "compare"(memory location) as follows (0:equal,1:first is greater,-1:second is greater)
        push si
        push di 
        push bx
        wile:     
        mov bx,[si]
        cmp [di],'$'
        je equal  
        cmp bx,[di]
        jne not_equal
        inc si
        inc di
        
        jmp wile
        
       not_equal:
          cmp bx,[di]
          ja great 
          jb less
          great:   
            mov byte ptr compare,1
            jmp rettt
          less:
            mov byte ptr compare,-1
            jmp rettt
       equal:
          mov byte ptr compare,0 
       rettt:
       pop bx
       pop di
       pop si
       ret
    compare_strings endp
    ;-------------------------
    copy_string proc
    ;role:copy string from a memory location to another
        push bp
        mov bp,sp
        push si
        push cx
        push bx 
        push ax
        mov si,[bp+4]
        mov bx,[bp+6]
        mov cx,16
     fr:mov al,[si]
        mov [bx],al
        inc bx
        inc si
        cmp al,'$'
        je tr 
        loop fr
   tr:  pop ax
        pop bx
        pop cx
        pop si
        pop bp
        ret 4
    copy_string endp
    ;-------------------------   
    printstring proc
    ;role:prints a string from an offset in dx to $
        mov ah,09h
        int 21h
        ret 
    printstring endp
    ;-------------------------
    clearscreen proc 
    ;role:clears the screen
        mov ah,0
        mov al,3
        int 10h     
        ret
    clearscreen endp  
    ;-------------------------
    readstring proc 
    ;role:reads a string from standard input to buffer
        mov ah,0Ah
        int 21h
        ret 
    readstring endp
    ;-------------------------
    init_buffer proc
    ;role: initialize the buffer
        push cx
        push di
        push ax  
        mov [buffer+1],0
        mov cl,[buffer]
        mov ch,0
        lea di,buffer+2
        mov al,0
        rep stosb
        pop ax
        pop di
        pop cx
        ret
    init_buffer endp
    ;------------------------- 
    sourcetobuffer proc 
        push bp
        mov bp,sp
        push bx
        push cx
        push di
        call init_buffer
        mov bx,[bp+4]
        mov cx,0
        mov di,2 
     wh:cmp [bx],'$'
        mov al,[bx]
        mov buffer[di],al
        inc cx
        inc di 
        inc bx
        cmp [bx],'$'
        je retu    
        cmp cx,16
        je retu
        jmp wh
        
        retu:
        mov buffer+1,cl 
        mov buffer+12,'$'
        pop di
        pop cx
        pop bx
        pop bp
        ret 2
    sourcetobuffer endp
    ;-------------------------
    buffertodest proc
    ;role: copies a string from the buffer to a memory location
        push bp
        mov bp,sp 
        push bx
        push cx
        push ax
        push di  
        mov buffer+12,'$'
        
        mov bx,[bp+4]
        mov cl,buffer+1 
        mov ch,0
        mov di,0
    for2:
        mov al,buffer[di+2]
        mov [bx+di],al 
        inc di
        loop for2
        mov al,'$'
        mov [bx+di],al 
        mov [bx+10],'$'
        pop di
        pop ax
        pop cx
        pop bx
        pop bp 
        ret 2
    buffertodest endp
    ;-------------------------
    exchange_strings proc   
        ;role:swap two strings from two different memory locations
        push bp
        mov bp,sp 
        push dx
        mov dx,[bp+6]
        push dx
        call sourcetobuffer
        mov dx,[bp+6]
        push dx
        mov dx,[bp+4]
        push dx
        call copy_string
        mov dx,[bp+4]
        push dx
        call buffertodest
        pop dx
        pop bp
        ret 4        

         

    exchange_strings endp
    ;-------------------------   
    sort_contacts proc  
        ;role:sorts the contacts based on alphabetic order (all the word)    //not working
        push dx
         push ax
         push bx
         push cx
         push si
         push di
         mov al,contacts_number
         cmp al,2
         jl tttt 

  repeat:
         mov cx,15
         dec cx
         mov di,0 
         mov bl,0
         mov swapped,bl
    for7:
         mov dx,di
         lea si,contacts[di]  
         mov di,si
         add di,23            
         call compare_strings 
         mov di,dx
         mov bl,compare
         cmp bl,0
         jle nxt
         mov bl,1
         mov swapped,bl  
         lea si,contacts[di]
         add si,23
         push si
         lea si,contacts[di]
         push si
         call exchange_strings
         lea si,contacts[di+11]
         add si,23
         push si
         lea si,contacts[di+11]
         push si
         call exchange_strings
         mov bl,contacts[di+45]
         mov bh,contacts[di+22]
         mov contacts[di+22],bl
         mov contacts[di+45],bh
     nxt:add di,23
         loop for7
         mov bl,swapped
         cmp bl,1
         je repeat

      tttt:
        pop di
         pop si
         pop cx
         pop bx
         pop ax
         pop dx
        ret
        sort_contacts endp
    ;------------------------- 
    sortcontacts proc  
        ;role:sorts the contacts based on alphabetic order (first character)
        push dx
         push ax
         push bx
         push cx
         push si
         push di  
         lea dx,loading
         call printstring
         
         mov al,contacts_number
         cmp al,2
         jl ttttt 

  repeat2:
         mov cx,15
         dec cx
         mov di,0 
         mov bl,0
         mov swapped,bl
    for9:
         lea si,contacts[di]  
         mov dx,di
         mov di,si
         add di,23 
         mov bl,[si]            
         cmp bl,[di]
         jle nxt2 
         mov di,dx
         mov bl,1
         mov swapped,bl  
         lea si,contacts[di]
         add si,23
         push si
         lea si,contacts[di]
         push si
         call exchange_strings
         lea si,contacts[di+11]
         add si,23
         push si
         lea si,contacts[di+11]
         push si
         call exchange_strings
         mov bl,contacts[di+45]
         mov bh,contacts[di+22]
         mov contacts[di+22],bl
         mov contacts[di+45],bh
     nxt2:
        mov di,dx
         add di,23
         loop for9
         mov bl,swapped
         cmp bl,1
         je repeat2

      ttttt:
        pop di
         pop si
         pop cx
         pop bx
         pop ax
         pop dx
        ret
        sortcontacts endp
    ;-------------------------
    
    add_a_contact proc
    ;role:adds a contact 
        cmp byte ptr[contacts_number],16
        jge full_contacts  
        lea si,contacts 
        mov cx,16
    for:cmp [si+22],0
        je add_contact
        add si,23
        loop for  
    add_contact:
        call init_buffer
        lea dx,entername
        call printstring
        lea dx,buffer
        call readstring
        push si
        call buffertodest
        call newline
        lea dx,enternumber
        call printstring
        lea dx,buffer 
        call init_buffer
        call readstring   
        mov dx,si
        add dx,11
        push dx     
        call buffertodest
        mov byte ptr[si+22],1
        mov dl,contacts_number
        inc dl
        mov contacts_number,dl
        jmp return
        full_contacts:
        lea dx,full
        call printstring
        call newline
        
    return:
        ret
    add_a_contact endp
    ;-------------------------  
    view_all_contacts proc
    ;role:shows an ordered list of all contacts with names and phone numbers
        call sortcontacts   
        call clearscreen
        cmp byte ptr[contacts_number],0
        jle empty_contacts  
        lea si,contacts 
        mov cx,16
   for3:cmp [si+22],0
        je l
        lea dx,names
        call printstring
        mov dx,si 
        call printstring
        call newline
        lea dx,number
        call printstring
        mov dx,si
        add dx,11
        call printstring
        call newline  
        lea dx,endcontact
        call printstring
        call newline
        
      l:add si,23
        loop for3 
        jmp return2 
    empty_contacts:
        lea dx,empty
        call printstring
        call newline 

        
    return2:
        ret
    view_all_contacts endp

    ;-------------------------
    search_a_contact proc
    ;role:searches for a contact using its name and prints its number if exists
        cmp contacts_number,0
        je  ncntcs
        lea dx,entername
        call printstring
        call init_buffer
        lea dx,buffer  
        call readstring
        mov si,1
        mov bl,buffer[si]
        mov bh,0
        mov si,bx
        mov buffer[si+2],'$'
        lea si,contacts
        lea di,buffer 
        add di,0002h
        mov cx,16 
   for4:cmp [si+22],0
        je lp
        call compare_strings
        mov bl,compare
        cmp bl,0
        je found 
 lp:    add si,23
        loop for4
        jmp notfound
 found: 
        call newline
        add si,11
        mov dx,si
        call printstring
        jmp retttt
 notfound:
        call newline
        lea dx,notfoundcontact
        call printstring
        call newline 
        jmp retttt
 ncntcs:            
        lea dx,empty
        call printstring
        call newline
        
   retttt:
        ret
    search_a_contact endp     
    ;-------------------------
    delete_a_contact proc
    ;role:delete a contact(logically;sets its existance variable to 0)
        cmp contacts_number,0
        je  nocontacts
        lea dx,entername
        call printstring
        call init_buffer
        lea dx,buffer  
        call readstring
        mov si,1
        mov bl,buffer[si]
        mov bh,0
        mov si,bx
        mov buffer[si+2],'$'
        lea si,contacts
        lea di,buffer 
        add di,2
        mov cx,16 
   for5:cmp [si+22],0
        je lpp
        call compare_strings
        mov bl,compare
        cmp bl,0
        je foundd 
 lpp:    add si,23
        loop for5
        jmp notfoundd
 foundd: 
        mov [si+22],0
        mov bl,contacts_number
        dec bl
        mov contacts_number,bl
        jmp rtt
 notfoundd:
        call newline
        lea dx,notfoundcontact
        call printstring
        call newline
        jmp rtt  
nocontacts:    
        call newline
        lea dx,empty
        call printstring
   rtt:
        ret
    delete_a_contact endp
    ;-------------------------
    modify_a_contact proc
    ;role:modifies a contact's number if exists
        
         cmp contacts_number,0
        je  nocontactss
        lea dx,entername
        call printstring
        call init_buffer
        lea dx,buffer  
        call readstring
        mov si,1
        mov bl,buffer[si]
        mov bh,0
        mov si,bx
        mov buffer[si+2],'$'
        lea si,contacts
        lea di,buffer 
        add di,2
        mov cx,16 
   for6:cmp [si+22],0
        je lppp
        call compare_strings
        mov bl,compare
        cmp bl,0
        je founddd 
 lppp:    add si,23
        loop for6
        jmp notfounddd
 founddd:               
        call newline
        lea dx,enternumber
        call printstring 
        call init_buffer
        lea dx,buffer
        call readstring
        mov dx,si
        add dx,11
        push dx
        call buffertodest
        jmp rttt
 notfounddd:
        call newline
        lea dx,notfoundcontact
        call printstring
        call newline
        jmp rtt  
nocontactss:    
        call newline
        lea dx,empty
        call printstring
   rttt:
        ret
     endp
    ;-------------------------  
ends

end start
