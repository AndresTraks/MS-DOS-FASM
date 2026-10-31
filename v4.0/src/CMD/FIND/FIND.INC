;;
;;  Long Conditional Jump Macros
;;
;; MASM's LOCAL gave each expansion a label of its own, and so does fasm's.
macro		lja	Farlabel {
		local	Nearlabel
		jna	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljae	Farlabel {
		local	Nearlabel
		jnae	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljb	Farlabel {
		local	Nearlabel
		jnb	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljc	Farlabel {
		local	Nearlabel
		jnc	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljbe	Farlabel {
		local	Nearlabel
		jnbe	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		lje	Farlabel {
		local	Nearlabel
		jne	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljz	Farlabel {
		local	Nearlabel
		jnz	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljg	Farlabel {
		local	Nearlabel
		jng	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljge	Farlabel {
		local	Nearlabel
		jnge	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljl	Farlabel {
		local	Nearlabel
		jnl	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljle	Farlabel {
		local	Nearlabel
		jnle	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljnc	Farlabel {
		local	Nearlabel
		jc	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljne	Farlabel {
		local	Nearlabel
		je	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljnz	Farlabel {
		local	Nearlabel
		jz	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljno	Farlabel {
		local	Nearlabel
		jo	Nearlabel
		jmp	Farlabel
Nearlabel:
}
macro		ljo	Farlabel {
		local	Nearlabel
		jno	Nearlabel
		jmp	Farlabel
Nearlabel:
}
