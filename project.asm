IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------

	x dw 0
	y dw 0
	zeroY dw 0
	zeroX dw 0
	mousePosX dw 0
	mousePosY dw 0

	Xsize dw 320
	Ysize dw 200
	
	canvasX equ 232
	canvasY equ 145
	offsetX equ 20
	offsetY equ 17
	
	color db 0
	color_buttons db 0, 255 ,249 ,250,251,252,253,254,248,2,3,4,5,6,7,8,64,192,72,200,71,199,23,15,55,184,183,195,230,232
	color_button_count equ 30
	
	x_size equ 320
	y_size equ 200
	filename db "test.bmp", 0
	filename2 db "test2.bmp", 0
	file_handle dw ?
	image_data db x_size * y_size + 1024 + 54 dup(2)
	
	
	button_tX dw 254, 254, 1, 1
	button_tY dw 15, 187, 35, 53
	button_bX dw 319, 319, 16, 16
	button_bY dw 89, 199, 50, 68
	button_count equ 4
	button_actions dw button_count dup(4)
	
	
	current_drawing_action db 0
	drawing_actions dw 2 dup(2)
	
	stroke db 3
;======UI ITEMS======

;======LETTERS=======
		
		
CODESEG


	jmp start
;====================================
;Main Procedures
;====================================
	;------------------------------
	;--------printing values-------
	;------------------------------
	proc print
	; Print red dot
	push ax
	push bx
	push cx
	push dx
	
	mov bh,0h ;
	push [x]
	push [y]
	
	pop dx
	pop cx
	
	;mov cx,[x]
	;mov dx,[y]
	mov al,[color]
	mov ah,0ch
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax

	ret
	endp print
	;----------------------

	;-----------------------
	proc print_rect
	; a procedure that prints a square using a set number of pixels
	; first in : x
	; second in : y
	
	push bp
	mov bp, sp
	
	
	push ax
	push cx
	push dx
	yCount equ [bp+4]
	xCount equ [bp+6]
	
	mov ax, [x]
	mov [zeroX], ax
	mov cx, yCount
	
	square_y_printer:
		push cx
		mov cx, xCount
		square_x_printer:
			call print
			inc [x]
			loop square_x_printer
		mov ax, [zeroX]
		mov [x], ax
		inc [y]
		pop cx
		loop square_y_printer
	mov ax, xCount
	sub [x], ax
	mov ax, yCount
	sub [y], ax
	
	pop dx
	pop cx
	pop ax
	pop bp
	ret
	endp print_rect
	
; ---------------------------------
; -------debug-tools---------------
; ---------------------------------

	macro debug_log message
		push ax
		push dx
		mov ah, 2
		mov dl, message
		int 21h
		pop dx
		pop ax
	endm debug_log

;---------------------------------
;---image reading procedures------
;---------------------------------
	
	macro open_file file
		mov ah, 03dh
		xor al, al
		mov dx, offset file
		int 21h
		mov [file_handle], ax
		;ret
	endm open_file
	
	macro close_file file
		push ax
		push bx
		mov ah, 03eh
		xor al, al
		mov bx, [file]
		int 21h
		pop bx
		pop ax
	endm close_file
	
	proc read_file
		mov ah, 03fh
		mov bx, [file_handle]
		mov cx, x_size*y_size + 1024 + 54
		mov dx, offset image_data
		int 21h
		ret
	endp read_file
	
	proc organize_image_in_correct_order
		push ds
		push 0A000h
		pop ds
		pop es
		xor di, di
		xor si, si
		mov cx, x_size*y_size
		mov di, offset image_data
		rep movsb
		push es
		pop ds
		ret
	endp organize_image_in_correct_order
	
	proc write_pallete
		mov si, offset image_data + 54
		
		mov dx,3C8h
		mov al,0 
		out dx,al
		inc dx 
		
		mov cx,256
		pallete_loop:
			mov al, [si+2]
			shr al, 2
			out dx,al
			mov al, [si+1]
			shr al, 2
			out dx,al
			mov al, [si]
			shr al, 2
			out dx,al
			add si, 4	
		loop pallete_loop
		
		ret
	endp write_pallete
	
	macro write_bitmap xs, ys, xoff, yoff
		local print_collum, write_row
		push es
		mov ax, 0A000h
		mov es, ax
		mov ax, 5
		
		xor di, di
		mov bx, xs*ys+xs
		mov cx, ys
		add di, xoff
		add di, yoff*x_size
		print_collum:
			push cx
			sub bx, xs
			sub bx, xs
			mov cx, xs
			write_row:
				
				
				mov al, [image_data + 1024 + 54 + bx]
				add bx, 1
				;sub di, 2
				stosb
		loop write_row
		pop cx
		mov dx, x_size
		sub dx, xs
		add di, dx
	loop print_collum
	endm write_bitmap
;==================================
;-------Read Mouse Input
;==================================
	proc UseMouse
	push ax
	push bx
		
		mov ax,3h
		int 33h
		
		shr cx, 1
		sub cx, 1
		sub dx, 1
		mov [x], cx
		mov [y], dx
		mov si, bx
		and si, 2
		and bx, 1
		cmp bx, 1
		je left_click
		mov ax,1h
		int 33h
		cmp si, 2
		je right_click
		jmp mouse_use_end
		left_click:
		
			; mov ax,2h
			; int 33h
			call check_for_canvas
			jmp mouse_use_end
			
		right_click:
			jmp mouse_use_end
		mouse_use_end:
		


	pop bx
	pop ax
	ret
	endp UseMouse
; -----------------------------------
; ---------keyboard-actions----------
; -----------------------------------
	proc use_keyboard
		mov ah, 1h
		int 16h
		cmp ax, 0
		je end_keyboard_read
		
		call change_stroke_size
		
		xor ax, ax
		end_keyboard_read:
		
		ret
	endp use_keyboard

	proc change_stroke_size
		cmp al, '1'
		jb end_stroke_change
		cmp al, '9'
		ja end_stroke_change
		mov [stroke], al
		sub [stroke], '0'
		end_stroke_change:
		call clearkeyboardbuffer
		ret
	endp change_stroke_size
	
	proc clearkeyboardbuffer		

		mov ah, 0ch
		int 21h
	
		ret
	endp clearkeyboardbuffer		
; -----------------------------------
; ---------button-handler------------
; -----------------------------------
	proc check_for_canvas
		push bx
		push bp
		mov bp, sp
		
		topx equ [word ptr bp-2]
		topy equ [word ptr bp-4]
		
		mov topx, offsetX
		mov bl, [stroke]
		xor bh, bh
		add topx, bx
		dec topx
		
		mov topy, offsetY
		add topy, bx
		dec topy
		
		sub sp, 4
			cmp cx, topx
			jb isnt_in_canvas
			cmp dx, topy
			jb isnt_in_canvas
			cmp cx, offsetX + canvasX
			jae isnt_in_canvas
			cmp dx, offsetY + canvasY
			jae isnt_in_canvas
		
			call drawing_action_manager
			jmp end_of_canvas_check
		isnt_in_canvas:
			
			call use_buttons

		end_of_canvas_check:
		add sp, 4 
		
		pop bp
		pop bx
		ret
	endp check_for_canvas

	proc use_buttons
		
		mov bx, cx
		mov cx, button_count
		xor si, si
		check_button_press:
			check_button_tx:
				cmp bx, [button_tX + si]
				jb button_check_failed
			check_button_bx:
				cmp bx, [button_bX + si]
				ja button_check_failed
			check_button_ty:
				cmp dx, [button_tY + si]
				jb button_check_failed
			check_button_by:
				cmp dx, [button_bY + si]
				ja button_check_failed
				
				jmp [button_actions + si]
			button_check_failed:
				add si, 2
				loop check_button_press
			jmp button_check_end
			
			button_action_one: ;Color picking button
				call pick_color
				jmp button_check_end
			button_action_two: ;Layer Deleting Button
				;write_bitmap canvasX, canvasY, offsetX, offsetY
				call clear_canvas
				jmp button_check_end
			button_action_three: ;button to select the main paint brush

				mov [current_drawing_action], 0
				
				jmp button_check_end
			button_action_four: ;button to select the eraser

				mov [current_drawing_action], 1
				jmp button_check_end
		button_check_end:
		ret
	endp use_buttons
	
	proc color_button_printer
		color_button_position_x equ 254
		color_button_position_y equ 15
		mov [x], color_button_position_x + 2
		mov [y], color_button_position_y + 2
		xor di, di
		push cx
			mov cx, 6
			colors_y_draw:
				push cx
				mov cx, 5
				colors_x_draw:
				mov al, [color_buttons + di]
				mov [color], al
				push 11
				push 11
				call print_rect
				pop si
				pop si
				add [x], 24
				inc di
				loop colors_x_draw
			pop cx
			sub [x], 13*5
			add [y], 12
			loop colors_y_draw
		pop cx
		ret
	endp color_button_printer
	
	proc pick_color
		color_button_position_x equ 254
		color_button_position_y equ 15

		xor si, si
		mov ax, [x]
		sub ax, color_button_position_x
		mov bx, 13 ; the number of pixels contained in each color square
		xor dx, dx
		div bx
		add si, ax
		mov ax, [y]
		sub ax, color_button_position_y
		xor dx, dx
		div bx
		mov bx, 5
		mul bx
		add si, ax
		mov al, [color_buttons + si]
		mov [color], al
		ret
	endp pick_color
	proc clear_canvas
		mov ax, 0A000h
		mov es, ax
		mov di, x_size*offsety
		add di, offsetX
		mov si, x_size*offsety
		add si, offsetX
		mov cx, canvasY
		clear_y:
			push cx
			mov cx, canvasX
			
			clear_x:
				mov al, [image_data + si]
				inc si
				stosb
				loop clear_x
			
			pop cx
			sub di, canvasX
			add di, x_size
			sub si, canvasX
			add si, x_size
			loop clear_y
		ret
	endp clear_canvas
; ---------------------------------
; ---------drawing-actions---------
; ---------------------------------
	proc erase
		
		mov cl, [stroke]
		erase_y:
			push cx
			mov cl, [stroke]
			erase_x:
				mov al, [color]
				push ax
				mov ax, [y]
				mov bx, x_size
				mul bx
				add ax, [x]
				mov bx, ax
				mov al, [image_data+bx]
				mov [color], al
				call print
				pop ax
				mov [color], al
				dec [x]
				loop erase_x
			pop cx
			mov al, [stroke]
			add [x], ax
			dec [y]
			loop erase_y
		ret
	endp erase
	proc draw
		mov cl, [stroke]
		draw_y:
			push cx
			mov cl, [stroke]
			draw_x:
				call print
				dec [x]
				loop draw_x
			pop cx
			mov al, [stroke]
			add [x], ax
			dec [y]
			loop draw_y
		ret
	endp draw
; ---------------------------------
; --------action-managers----------
; ---------------------------------
proc drawing_action_manager
	push ax
	push bx
	
	mov bl, [current_drawing_action]
	xor bh, bh
	shl bx, 1
	
	jmp [drawing_actions + bx]
	drawing_action_one: ;the main paint brush
		call draw
		jmp end_drawing_actions
	drawing_action_two:
		call erase
		jmp end_drawing_actions
	end_drawing_actions:
	pop bx
	pop ax
	
	ret
endp drawing_action_manager



;==================================
;-----MAIN CODE--------------------
;==================================

start:
	mov ax, @data
	mov ds, ax
	

	; Graphic mode
	mov ax, 13h
	int 10h
	
	
	
code_start:
	mov [x], 0
	mov [y], 0
	open_file filename
	call read_file
	call write_pallete 
	
	write_bitmap 320, 200, 0, 0
	
	open_file filename2
	call read_file
	;call write_pallete 
	write_bitmap canvasX, canvasY, offsetX, offsetY
	call organize_image_in_correct_order
	call color_button_printer
	mov [color], 0

	mov dx, offset button_action_one
	mov [word ptr button_actions], dx
	
	mov dx, offset button_action_two
	mov [word ptr button_actions + 2], dx
	
	mov dx, offset button_action_three
	mov [word ptr button_actions + 4], dx
	
	mov dx, offset button_action_four
	mov [word ptr button_actions + 6], dx
	
	;define drawing actions
	mov dx, offset drawing_action_one
	mov [word ptr drawing_actions], dx
	
	mov dx, offset drawing_action_two
	mov [word ptr drawing_actions + 2], dx
	
	mov [current_drawing_action], 0
	
	mov ax,0h
	int 33h
	
	mov ax, 01ch
	mov bx, 4
	int 33h
	
	mov ax,1h
	int 33h
	
	mov ax, 000cH
	int 33h
	
	mov  ax,1003h                
    mov  bl,00h                  
    int  10h  
	
	
end_software:

	call UseMouse
	call use_keyboard
	jmp end_software	
	
exit:
	mov ax, 4c00h
	int 21h
END start