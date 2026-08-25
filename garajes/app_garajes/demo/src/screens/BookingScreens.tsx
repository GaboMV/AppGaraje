import React, { useState } from 'react';
import { ArrowLeft, MapPin, Calendar, Store, Info, Lock, Send, MoreVertical, CheckCircle, QrCode, CreditCard, Star } from 'lucide-react';

export function BookingRequest({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col bg-white">
      <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-sm border-b border-slate-100">
        <div className="px-4 h-14 flex items-center justify-between">
          <button onClick={() => onNavigate('GarageDetails')} className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-100">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-base font-bold flex-1 text-center pr-10">Solicitar Reserva</h1>
        </div>
      </header>

      <main className="flex-1 flex flex-col p-4 pb-32">
        <section className="bg-slate-50 rounded-xl p-4 border border-slate-100 mb-6">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-500 mb-3">Resumen de reserva</h2>
          <div className="flex gap-4 mb-4">
            <div className="w-24 h-24 rounded-lg overflow-hidden shrink-0">
              <img src="https://images.unsplash.com/photo-1605810230434-7631ac76ec81?auto=format&fit=crop&q=80&w=200" alt="Garage" className="w-full h-full object-cover" />
            </div>
            <div className="flex flex-col justify-between py-0.5">
              <div>
                <h3 className="font-bold text-sm leading-tight mb-1">Garage Espacioso en Palermo</h3>
                <p className="text-xs text-slate-500 flex items-center gap-1">
                  <MapPin className="w-3 h-3" /> Palermo Soho, CABA
                </p>
              </div>
              <div>
                <span className="inline-flex px-2 py-1 rounded bg-primary/10 text-primary text-xs font-semibold">
                  $12,500 ARS
                </span>
              </div>
            </div>
          </div>
          
          <div className="space-y-3 pt-4 border-t border-slate-200">
            <div className="flex items-start gap-3">
              <Calendar className="text-primary w-5 h-5 shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium">12 Oct - 14 Oct</p>
                <p className="text-xs text-slate-500">Viernes, Sábado, Domingo</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <Store className="text-primary w-5 h-5 shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium">Extras incluidos</p>
                <p className="text-xs text-slate-500">Mesa plegable grande (x1), Acceso a electricidad</p>
              </div>
            </div>
          </div>
        </section>

        <section className="flex flex-col flex-1">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-lg font-bold">Mensaje al propietario</h3>
            <span className="text-xs font-semibold text-rose-500 bg-rose-50 px-2 py-0.5 rounded-full">Obligatorio</span>
          </div>
          <p className="text-sm text-slate-600 mb-4 leading-relaxed">
            Cuéntale a <span className="font-semibold">Martín</span> qué planeas vender. Una buena presentación aumenta tus posibilidades de aceptación.
          </p>
          <div className="relative flex-1">
            <textarea 
              className="w-full h-48 p-4 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-primary outline-none resize-none text-sm"
              placeholder="Hola, soy diseñadora de indumentaria y me gustaría usar el espacio para vender mi colección..."
            ></textarea>
            <div className="absolute bottom-3 right-3 text-xs text-slate-400 font-medium">0 / 500</div>
          </div>
          <div className="mt-2 flex items-start gap-2">
            <Info className="text-slate-400 w-4 h-4 shrink-0 mt-0.5" />
            <p className="text-xs text-slate-500">Escribe al menos 50 caracteres para dar confianza al anfitrión.</p>
          </div>
        </section>
      </main>

      <footer className="fixed bottom-0 left-0 w-full bg-white border-t border-slate-100 p-4 pb-8 z-40">
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-center gap-1.5 text-xs text-slate-500 mb-1">
            <Lock className="w-3 h-3" />
            <span>No se te cobrará nada todavía</span>
          </div>
          <button onClick={() => onNavigate('ChatPayment')} className="w-full bg-primary text-white font-bold py-3.5 px-4 rounded-xl shadow-lg shadow-primary/20 flex items-center justify-center gap-2">
            <span>Enviar Solicitud</span>
            <Send className="w-5 h-5" />
          </button>
        </div>
      </footer>
    </div>
  );
}

export function ChatPayment({ onNavigate }: { onNavigate: (s: any) => void }) {
  const [showPayment, setShowPayment] = useState(false);

  return (
    <div className="flex-1 flex flex-col bg-slate-50 relative overflow-hidden">
      <div className="flex items-center bg-white p-4 border-b border-slate-100 z-20 shrink-0">
        <button onClick={() => onNavigate('BookingRequest')} className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-100">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div className="flex-1 text-center">
          <h2 className="text-lg font-bold leading-tight">Chat con Propietario</h2>
          <p className="text-xs text-primary font-medium">En línea</p>
        </div>
        <button className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-100">
          <MoreVertical className="w-6 h-6" />
        </button>
      </div>

      <div className="bg-primary/5 border-b border-primary/10 p-4 flex items-center justify-between gap-4 z-10 shrink-0">
        <div className="flex flex-col">
          <div className="flex items-center gap-1.5 text-primary font-bold text-sm">
            <CheckCircle className="w-5 h-5 fill-primary/20" />
            Solicitud Aceptada
          </div>
          <p className="text-xs text-slate-500 mt-0.5">La reserva expira en 23:58h</p>
        </div>
        <button onClick={() => setShowPayment(true)} className="bg-primary text-white text-sm font-bold py-2.5 px-5 rounded-lg shadow-lg shadow-primary/20">
          PAGAR $150.00
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-6 pb-24">
        <div className="flex justify-center">
          <span className="text-xs font-medium text-slate-400 bg-slate-100 px-3 py-1 rounded-full">Hoy, 10 de Octubre</span>
        </div>

        <div className="flex items-end gap-3">
          <div className="w-8 h-8 rounded-full bg-slate-200 overflow-hidden shrink-0">
            <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150" alt="Host" className="w-full h-full object-cover" />
          </div>
          <div className="flex flex-col gap-1 max-w-[75%]">
            <span className="text-xs text-slate-500 ml-1">Ana María</span>
            <div className="bg-white p-3 rounded-2xl rounded-bl-none shadow-sm border border-slate-100">
              <p className="text-sm leading-relaxed">
                ¡Hola! He revisado tu perfil y me encanta tu tienda vintage. ¡Acepto la solicitud! El espacio estará listo para ti el sábado.
              </p>
            </div>
            <span className="text-[10px] text-slate-400 ml-1">10:30 AM</span>
          </div>
        </div>

        <div className="flex items-end gap-3 justify-end">
          <div className="flex flex-col gap-1 items-end max-w-[75%]">
            <div className="bg-primary text-white p-3 rounded-2xl rounded-br-none shadow-md">
              <p className="text-sm leading-relaxed">
                ¡Genial! Muchas gracias Ana. Procederé con el pago ahora mismo.
              </p>
            </div>
            <span className="text-[10px] text-slate-400">10:32 AM</span>
          </div>
        </div>

        <div className="flex justify-center my-4">
          <div className="bg-slate-200/50 px-4 py-2 rounded-lg text-center max-w-[85%]">
            <p className="text-xs text-slate-600">
              <span className="font-bold">Sistema:</span> La solicitud ha sido aprobada. Tienes 24h para realizar el pago.
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white p-3 border-t border-slate-100 flex items-center gap-3 shrink-0">
        <button className="text-slate-400 p-1"><Store className="w-6 h-6" /></button>
        <div className="flex-1 bg-slate-100 rounded-full h-10 px-4 flex items-center">
          <span className="text-slate-400 text-sm">Escribe un mensaje...</span>
        </div>
        <button className="w-10 h-10 bg-primary/10 text-primary rounded-full flex items-center justify-center">
          <Send className="w-5 h-5" />
        </button>
      </div>

      {showPayment && (
        <>
          <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-[2px] z-30" onClick={() => setShowPayment(false)}></div>
          <div className="absolute bottom-0 left-0 w-full bg-white rounded-t-3xl shadow-[0_-8px_30px_rgba(0,0,0,0.12)] z-40">
            <div className="w-full flex justify-center pt-3 pb-1">
              <div className="w-12 h-1.5 bg-slate-200 rounded-full"></div>
            </div>
            <div className="p-6 pt-2 pb-8">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h3 className="text-xl font-bold">Finalizar Reserva</h3>
                  <p className="text-sm text-slate-500">Total a pagar: <span className="text-primary font-bold">$150.00</span></p>
                </div>
              </div>
              
              <div className="space-y-3">
                <label className="flex items-center justify-between p-4 rounded-xl border border-primary bg-primary/5 cursor-pointer">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-lg bg-white text-primary flex items-center justify-center shadow-sm">
                      <QrCode className="w-6 h-6" />
                    </div>
                    <div>
                      <h4 className="font-bold text-sm">Transferencia QR</h4>
                      <p className="text-xs text-primary font-medium">Recomendado · Instantáneo</p>
                    </div>
                  </div>
                  <input type="radio" name="payment" defaultChecked className="w-5 h-5 text-primary border-slate-300 focus:ring-primary" />
                </label>
                
                <label className="flex items-center justify-between p-4 rounded-xl border border-slate-200 cursor-pointer">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center">
                      <CreditCard className="w-6 h-6" />
                    </div>
                    <div>
                      <h4 className="font-bold text-sm">Tarjeta de Crédito/Débito</h4>
                      <p className="text-xs text-slate-400 mt-0.5">Visa, MC</p>
                    </div>
                  </div>
                  <input type="radio" name="payment" className="w-5 h-5 text-primary border-slate-300 focus:ring-primary" />
                </label>
              </div>

              <div className="mt-6">
                <button onClick={() => onNavigate('Rating')} className="w-full bg-primary text-white font-bold py-4 px-6 rounded-xl shadow-lg shadow-primary/25 flex items-center justify-center gap-2">
                  <span>CONFIRMAR PAGO</span>
                  <ArrowLeft className="w-4 h-4 rotate-180" />
                </button>
                <div className="flex items-center justify-center gap-1.5 mt-4 text-slate-400">
                  <Lock className="w-3 h-3" />
                  <span className="text-[10px] font-medium uppercase tracking-wide">Transacción 100% Segura</span>
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export function Rating({ onNavigate }: { onNavigate: (s: any) => void }) {
  const [showSuccess, setShowSuccess] = useState(false);

  const handleSubmit = () => {
    setShowSuccess(true);
  };

  return (
    <div className="flex-1 flex flex-col bg-slate-50 relative overflow-hidden">
      <header className="flex items-center justify-between p-4 sticky top-0 z-10 bg-slate-50/95 backdrop-blur-sm">
        <button onClick={() => onNavigate('Home')} className="p-2 rounded-full hover:bg-slate-200">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-sm font-bold tracking-wider uppercase text-slate-500">Calificación Mutua</h1>
        <div className="w-10"></div>
      </header>

      <main className="flex-1 overflow-y-auto px-6 pb-24">
        <div className="mt-4 mb-8 text-center">
          <h2 className="text-3xl font-extrabold tracking-tight leading-tight">
            ¿Cómo fue tu<br/>experiencia?
          </h2>
          <p className="text-slate-500 mt-2 text-sm">Tu opinión ayuda a mejorar la comunidad.</p>
        </div>

        <section className="mb-10">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold">Califica al Dueño</h3>
            <span className="bg-emerald-100 text-emerald-700 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide">Dueña</span>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
            <div className="flex flex-col items-center mb-6">
              <div className="relative mb-3">
                <div className="w-20 h-20 rounded-full overflow-hidden ring-4 ring-slate-50 shadow-lg">
                  <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150" alt="Owner" className="w-full h-full object-cover" />
                </div>
                <div className="absolute bottom-0 right-0 bg-emerald-400 rounded-full p-1 border-2 border-white">
                  <CheckCircle className="w-4 h-4 text-white" />
                </div>
              </div>
              <h4 className="text-xl font-bold">María González</h4>
              <p className="text-sm text-slate-500">Dueña del espacio</p>
            </div>
            
            <div className="flex justify-center gap-2 mb-6">
              {[1, 2, 3, 4, 5].map((i) => (
                <button key={i} className="focus:outline-none">
                  <Star className={`w-10 h-10 ${i <= 4 ? 'text-emerald-400 fill-emerald-400' : 'text-slate-200'}`} />
                </button>
              ))}
            </div>

            <textarea 
              className="w-full bg-slate-50 border-none rounded-xl placeholder:text-slate-400 focus:ring-2 focus:ring-emerald-400 p-4 text-sm resize-none" 
              placeholder="¿Algo que destacar sobre María?" 
              rows={2}
            ></textarea>
          </div>
        </section>

        <section className="mb-8">
          <h3 className="text-lg font-bold mb-4">Califica el Espacio</h3>
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-slate-100 flex gap-4 items-center">
            <div className="w-20 h-20 shrink-0 rounded-lg overflow-hidden">
              <img src="https://images.unsplash.com/photo-1605810230434-7631ac76ec81?auto=format&fit=crop&q=80&w=200" alt="Space" className="w-full h-full object-cover" />
            </div>
            <div className="flex-1">
              <h4 className="font-bold leading-tight mb-1">Garage techado en Palermo</h4>
              <p className="text-xs text-slate-500 mb-2">Av. Santa Fe 3200, Buenos Aires</p>
              <div className="flex gap-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <Star key={i} className={`w-6 h-6 ${i <= 3 ? 'text-emerald-400 fill-emerald-400' : 'text-slate-200'}`} />
                ))}
              </div>
            </div>
          </div>
        </section>
      </main>

      <div className="fixed bottom-0 left-0 right-0 p-4 bg-slate-50/80 backdrop-blur-md border-t border-slate-200 z-20">
        <button onClick={handleSubmit} className="w-full bg-emerald-400 hover:bg-emerald-500 text-white text-base font-bold py-4 px-6 rounded-xl shadow-lg shadow-emerald-400/20 flex items-center justify-center gap-2">
          <span>Enviar Calificación</span>
          <ArrowLeft className="w-5 h-5 rotate-180" />
        </button>
      </div>

      {showSuccess && (
        <div className="absolute inset-0 bg-slate-50 z-50 flex flex-col items-center justify-center p-8 text-center">
          <div className="w-24 h-24 rounded-full bg-emerald-400/20 flex items-center justify-center mb-6">
            <CheckCircle className="w-16 h-16 text-emerald-400" />
          </div>
          <h2 className="text-3xl font-bold mb-2">¡Gracias por tu opinión!</h2>
          <p className="text-slate-500 max-w-[250px] mx-auto">Tu comentario ha sido enviado y ayudará a otros usuarios.</p>
          <button onClick={() => onNavigate('Home')} className="mt-12 text-emerald-500 font-bold hover:underline">
            Volver al inicio
          </button>
        </div>
      )}
    </div>
  );
}
