; ImageInfo structure layout
img_width		EQU 0
img_height		EQU 4
img_linebytes	EQU 8
img_bitsperpel	EQU 12
img_pImg		EQU	16


section .bss
idx resb 1  ; rezerwuje jeden bajt na indeks


section	.text
global _decode128, decode128
extern code128_ascii_table, _code128_ascii_table

_decode128:
decode128:
	push ebp
	mov	ebp, esp
	push ebx
    push esi
    push edi
    mov	eax, DWORD [ebp+8]	; eax <- address of image info struct
    mov ebx, [eax + img_pImg]      ; przenieś adres pierwszego byte'u
    mov ecx, [eax + img_height]  ; przenieś wartość height do rejestru ecx
    mov edx, [eax + img_linebytes]  ; przeniesc lbytes do edx
    mov eax, [ebp + 12] ; eax = bufor wynikowy

    shr ecx, 1 ; height / 2
    imul ecx, edx ; ecx = (height/2) * lbytes = offset do srodkowej linii pliku
    add ecx, ebx ; ecx = adres pierwszego byte'u w srodkowej linii / read pointer

    mov bh, byte [ecx]  ; bh = wartosc pierwszego wczytanego bajtu
    mov bl, bh ; utrzymujemy wartosc wczytanego bajtu
    shr bh, 4 ; przesuwamy w prawo o cztery zeby miec pierwszy pixel(pierwsze 4 bity)
    mov dh, bh  ; dh = nasz pixel tla

    and bl, 0xF ; usun wszystko oprocz ostatnich 4 bitow czyli zostaw 2 pixel z bajtu

    cmp bl, dh ; zobacz czy jest to pixel tla

    jne read_even_char ; jezeli nie to mamy nasz pierwszy bar i czytamy calosc
    inc ecx ; przejdz na kolejny bajt

find_first_bar:
    mov bh, byte [ecx]; load next byte
    mov bl, bh ; utrzymujemy wartosc wczytanego bajtu
    shr bh, 4 ; shift zeby wziac 1 pixel

    cmp bh, dh
    jne read_odd_char ; jesli rozpoczecie barcodu to czytaj

    and bl, 0xF ; and zeby zostal 2 pixel
    cmp bl, dh
    jne read_even_char ; jesli rozpoczecie barcodu to czytaj
    inc ecx ; przejdz na kolejny byte
    jmp find_first_bar



read_odd_char:
    ;argument - ecx = address of byte where to start reading char
    mov edi, 0x1 ; edi = character code
    mov bh, byte [ecx]; load byte
    shr bh, 4 ; shift zeby wziac 1 pixel
    mov dl, bh ; dl = last pixel
    mov dh, 5 ; dh = loop iterator

read_odd_char_loop:
    mov bh, byte [ecx]; load byte
    and bh, 0xF ; and zeby zostal 2 pixel

    cmp bh, dl
    je recl_samethighodd ; jesli taki sam jak poprzedni to pomin ponizsze akcje

    shl edi, 4 ; Przesuń zawartość rejestru edi o 4 bity w lewo
    mov dl, bh ; dl = new last pixel
recl_samethighodd:
    inc edi
    inc ecx ; incrementuj byte address
    mov bh, byte [ecx]; load byte
    shr bh, 4

    cmp bh, dl
    je recl_samethighodd2

    shl edi, 4 ; make space for another module
    mov dl, bh ; dl = new last pixel
recl_samethighodd2:
    inc edi

    dec dh
    cmp dh, 0    ; Porównaj zawartość rejestru dh z zerem
    jne read_odd_char_loop
read_odd_char_end:
    call find_char
    cmp dl, 100
    je end_of_function
    mov dl, 0
    jmp read_even_char



read_even_char:
    ;argument - ecx = address of byte where to start reading char
    mov edi, 0x1 ; edi = character code
    mov bh, byte [ecx]; load byte
    and bh, 0xF ; and zeby zostal 2 pixel
    mov dl, bh ; dl = last pixel
    inc ecx ; increment byte address
    mov dh, 5 ; dh = loop iterator

read_even_char_loop:
    mov bh, byte [ecx]; load byte
    mov bl, bh ; preserve our byte for the next pixel
    shr bh, 4 ; shift zeby wziac 1 pixel

    cmp bh, dl
    je recl_samethighev ; jesli taki sam jak poprzedni to pomin ponizsze akcje

    shl edi, 4 ; Przesuń zawartość rejestru edi o 4 bity w lewo
    mov dl, bh ; dl = new last pixel
recl_samethighev:
    inc edi

    and bl, 0xF ; and zeby zostal 2 pixel z bajtu ktory zachowalismy

    cmp bl, dl
    je recl_samethighev2

    shl edi, 4 ; make space for another module
    mov dl, bl ; dl = new last pixel
recl_samethighev2:
    inc edi
    inc ecx

    dec dh
    cmp dh, 0    ; Porównaj zawartość rejestru dh z zerem
    jne read_even_char_loop

read_even_char_end:

    call find_char
    cmp dl, 100
    je end_of_function
    mov dl, 0
    jmp read_odd_char




find_char:
    ;character code jest w edi
    mov esi, 0x211214
    cmp edi, esi
    jne not_code_B
    ret
not_code_B:
    mov esi, code128_ascii_table ; esi - wskaznik na poczatek tablicy
    mov dl, 0 ; index tablicy
find_char_loop:

    mov ebx, [esi]      ; Pobierz wzorzec kodu

    cmp edi, ebx       ; Sprawdź, czy wzorzec kodu jest nie równy poszukiwanej wartości
    jne not_found           ; Jeśli tak, skocz do etykiety not_found

    ; Pobierz odpowiadający znak ASCII (z 4 bajtów po wzorcu)
    mov edx, [esi+4]

    mov ebx, 0
    mov bl, [idx] ; wez nasz indeks

    ; Przeniesienie znaku do bufora
    mov [eax + ebx], edx

    inc bl
    mov [idx], bl
    ret

not_found:

    add esi, 8          ; Przesuń wskaźnik do następnego wpisu (4 bajty dla wzorca, 4 bajty dla znaku)
    inc dl ; increment index

    cmp dl, 95 ; zakladamy ze nasza lista ma 95 znakow(tak jest)
    jl find_char_loop       ; jesli index mniejszy niz 90 to kontynuuj petle

    ; No sign found, exit
    mov dl, 100 ; dl = 100 - if sign not found at all
    ret



end_of_function:

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop	ebp
	ret ; w eax ma byc adres do bufora buffer czyli mov eax, buffer