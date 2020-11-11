// PDEPFONI

object empresaDeTelefonia{
	var property costoMB = 0.5
	var property costoFijoLlamadas = 1
	var property costoPorSegundo = 0.05
}

class Linea{
	var numero
	const packsActivos = []
	const consumos= []
	var deuda= 0
	var linea 
	const hoy = new Date()
	
	method numeroLinea()= numero
	method deudaAcumulada()= deuda
	method cambiarLinea(lineaNueva){linea = lineaNueva}
	method contratarPack(pack){packsActivos.add(pack)}
	method unPackLoCubre(consumo)= packsActivos.any({pack => pack.cubre(consumo)})
	method consumirPack(consumo){
		var pack = packsActivos.reverse().find({pack => pack.cubre(consumo)})
		pack.consumir(consumo)
	}
	method limpiezaPacks(){
		packsActivos.removeAllSuchThat({pack => not pack.estaVencidoEn(hoy) and not pack.termino()})
	}
	method consumir(consumo){
		if(self.unPackLoCubre(consumo)){
		self.consumirPack(consumo)
		consumos.add(consumo)
		}else{
			if(linea.permiteRealizarConsumoSinPack()){
			consumos.add(consumo)
			deuda += linea.deudaCorrespondiente(consumo)
			}
		}
	}
	method consumosEntre(min,max)= consumos.filter({consumo => consumo.fecha().between(min,max)})
	method consumoPromedioEntre(min,max) = 
	self.consumosEntre(min,max).sum({consumo => consumo.costo()}) / self.consumosEntre(min,max).size()
	method consumoDelMes()= self.consumosEntre(hoy.minusDays(30),hoy).sum({consumo => consumo.costo()})
}

// CONSUMO

class Consumo{
	var fecha
	var cantidadConsumida
	
	method fecha()= fecha
	method costo()
	method esLlamada()
	method esInternet()	
	method cuantoConsumio() = cantidadConsumida
}

class ConsumoMB inherits Consumo{
	
	override method costo()= cantidadConsumida*empresaDeTelefonia.costoMB()
	override method esInternet()= true
	override method esLlamada()= false
}

class ConsumoLlamada inherits Consumo{
	
	override method costo(){
		if( cantidadConsumida>30)
		return empresaDeTelefonia.costoFijoLlamadas()+empresaDeTelefonia.costoPorSegundo()*( cantidadConsumida-30)
		else
		return empresaDeTelefonia.costoFijoLlamadas()
	}
	override method esInternet()= false
	override method esLlamada()= true
}

// PACKS

class Pack{
	var fechaVencimiento
	const hoy = new Date()
	
	method cubre(consumo)
	method satisfaceConsumo(consumo)
	method estaVencido() = hoy > fechaVencimiento
	method consumir(consumo)
	method termino()
}

class PackConsumible inherits Pack{
	var cantidadConsumible
	const consumiciones=[]
	
	override method cubre(consumo) = (not self.estaVencido() and not self.termino()) and self.satisfaceConsumo(consumo)
	method cantidadRestante()= cantidadConsumible - consumiciones.sum({consumo => consumo.cuantoConsumio()})
	override method consumir(consumo){consumiciones.add(consumo)}
	override method termino()= self.cantidadRestante() <= 0
}

class PackCredito inherits PackConsumible{
	
	override method satisfaceConsumo(consumo)= consumo.costo()<= cantidadConsumible
}

class PackInternet inherits PackConsumible{
	 override method satisfaceConsumo(consumo)= consumo.esInternet()
}

class PackInternetPlus inherits PackConsumible{
	override method cubre(consumo){
		if(not self.termino())
		return not self.estaVencido() and self.satisfaceConsumo(consumo)
		else
		return consumo.cuantoConsumio() <= 0.5 
	}
	override method satisfaceConsumo(consumo)= consumo.esInternet()
}

class PackIlimitado inherits Pack{
	override method cubre(consumo)= not self.estaVencido() and self.satisfaceConsumo(consumo)
	override method termino()= false
}

class PackLlamadasGratis inherits PackIlimitado{
	override method satisfaceConsumo(consumo)= consumo.esLlamada()
}

class PackInternetIlimitadoLosFindes inherits PackIlimitado{
	override method satisfaceConsumo(consumo)= consumo.esInternet() and consumo.fecha().internalDayOfWeek() > 5
}

// LINEAS

object comun{
	
	method permiteRealizarConsumoSinPack()= false
}

object black{
	method permiteRealizarConsumoSinPack()= true
	method deudaCorrespondiente(consumo)= consumo.costo()
}

object platinum{
	method permiteRealizarConsumoSinPack()= true
	method deudaCorrespondiente(consumo)= 0
}