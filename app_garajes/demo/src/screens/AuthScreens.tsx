import React, { useState, useRef } from 'react';
import { ArrowLeft, Mail, Store, Home as HomeIcon, Search, Eye, EyeOff } from 'lucide-react';

export function Onboarding({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col relative">
      <div className="h-12 w-full flex items-center justify-between px-6 pt-4 absolute top-0 z-10">
        <div className="flex items-center gap-2 text-primary font-bold text-xl tracking-tight">
          <Store className="w-6 h-6" />
          <span>GarageSale</span>
        </div>
        <button onClick={() => onNavigate('AuthMethod')} className="text-slate-500 text-sm font-semibold hover:text-primary transition-colors">
          Saltar
        </button>
      </div>
      
      <div className="flex-1 flex flex-col justify-center px-8 pt-16">
        <div className="w-full aspect-[4/5] max-h-[400px] mb-8 relative rounded-3xl overflow-hidden shadow-2xl shadow-primary/10">
          <div className="absolute inset-0 bg-gradient-to-br from-indigo-100 to-white opacity-50 z-0"></div>
          <img src="https://images.unsplash.com/photo-1555529771-835f59fc5efe?auto=format&fit=crop&q=80&w=800" alt="Shopping" className="absolute inset-0 w-full h-full object-cover z-10" />
        </div>
        <div className="text-center space-y-3">
          <h2 className="text-3xl font-extrabold text-slate-900 leading-tight">
            Encuentra <span className="text-primary">espacios únicos</span>
          </h2>
          <p className="text-slate-500 text-base leading-relaxed">
            Explora garajes y pop-ups cerca de ti para encontrar tesoros escondidos o el lugar perfecto.
          </p>
        </div>
      </div>

      <div className="w-full px-6 pb-10 pt-6">
        <div className="flex flex-col gap-4">
          <button onClick={() => onNavigate('AuthMethod')} className="w-full h-14 bg-primary text-white text-lg font-bold rounded-xl shadow-lg shadow-primary/30 active:scale-[0.98] transition-all">
            Crear Cuenta
          </button>
          <button onClick={() => onNavigate('AuthMethod')} className="w-full h-14 bg-transparent border-2 border-primary text-primary text-lg font-bold rounded-xl active:scale-[0.98] transition-all">
            Iniciar Sesión
          </button>
        </div>
      </div>
    </div>
  );
}

export function AuthMethod({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col">
      <div className="w-full flex-1 flex flex-col items-center pt-8 px-6">
        <div className="mb-8 relative w-full aspect-[4/3] rounded-2xl overflow-hidden shadow-lg group">
          <div className="absolute inset-0 bg-gradient-to-tr from-primary/80 to-purple-500/50 mix-blend-multiply z-10"></div>
          <img src="https://images.unsplash.com/photo-1531058020387-3be344556be6?auto=format&fit=crop&q=80&w=800" alt="Community" className="w-full h-full object-cover" />
          <div className="absolute bottom-4 left-4 z-20 bg-white/90 backdrop-blur-sm p-3 rounded-xl shadow-sm">
            <Store className="text-primary w-8 h-8" />
          </div>
        </div>
        <div className="text-center w-full max-w-xs mx-auto mb-8">
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 mb-3">
            Únete a la <span className="text-primary">comunidad</span>
          </h1>
          <p className="text-slate-500 text-base leading-relaxed">
            Descubre tesoros únicos y encuentra las mejores ventas de garaje cerca de ti.
          </p>
        </div>
      </div>

      <div className="w-full px-6 pb-6 flex flex-col gap-4">
        <button className="relative w-full flex items-center justify-center h-14 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
          <span className="font-bold text-slate-700">Continuar con Google</span>
        </button>
        <button className="relative w-full flex items-center justify-center h-14 bg-black text-white rounded-xl hover:opacity-90 transition-opacity">
          <span className="font-bold">Continuar con Apple</span>
        </button>
        
        <div className="relative flex py-2 items-center">
          <div className="flex-grow border-t border-slate-200"></div>
          <span className="mx-4 text-slate-400 text-sm font-medium uppercase">o</span>
          <div className="flex-grow border-t border-slate-200"></div>
        </div>

        <button onClick={() => onNavigate('Register')} className="w-full flex items-center justify-center h-14 bg-primary text-white rounded-xl hover:bg-primary/90 transition-colors shadow-lg shadow-primary/25">
          <Mail className="mr-2 w-5 h-5" />
          <span className="font-bold">Registrarse con Correo</span>
        </button>
      </div>
      
      <div className="w-full px-6 pb-8 text-center">
        <p className="text-slate-600 font-medium mb-6">
          ¿Ya tienes cuenta? <button className="text-primary font-bold ml-1">Inicia sesión</button>
        </p>
      </div>
    </div>
  );
}

export function Register({ onNavigate }: { onNavigate: (s: any) => void }) {
  const [showPassword, setShowPassword] = useState(false);

  return (
    <div className="flex-1 flex flex-col">
      <header className="flex items-center justify-between px-4 py-3 sticky top-0 z-10 bg-white/95 backdrop-blur-sm">
        <button onClick={() => onNavigate('AuthMethod')} className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h2 className="text-lg font-bold flex-1 text-center pr-10">Crear Cuenta</h2>
      </header>

      <main className="flex-1 flex flex-col px-6 pt-2 pb-8">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 mb-2">Bienvenido a GarageSale</h1>
          <p className="text-slate-500 font-medium">Completa tus datos para encontrar tu espacio ideal.</p>
        </div>

        <form className="space-y-6 flex-1 flex flex-col" onSubmit={(e) => { e.preventDefault(); onNavigate('OTPVerification'); }}>
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-slate-900">Nombre Completo</label>
            <input type="text" placeholder="Ej. Juan Pérez" className="w-full px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" />
          </div>
          
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-slate-900">Correo Electrónico</label>
            <input type="email" placeholder="Ej. juan@email.com" className="w-full px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" />
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-slate-900">Contraseña</label>
            <div className="relative">
              <input type={showPassword ? "text" : "password"} placeholder="••••••••" className="w-full px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all" />
              <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400">
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-2">
            <input type="checkbox" id="terms" className="w-5 h-5 rounded border-slate-300 text-primary focus:ring-primary" />
            <label htmlFor="terms" className="text-sm font-medium text-slate-600">
              Acepto los <span className="text-primary font-bold underline">Términos y Condiciones</span>
            </label>
          </div>

          <div className="flex-1"></div>

          <button type="submit" className="w-full py-4 bg-primary text-white font-bold rounded-lg shadow-lg shadow-primary/30 active:scale-[0.98] transition-all">
            Registrarme
          </button>
        </form>
      </main>
    </div>
  );
}

export function OTPVerification({ onNavigate }: { onNavigate: (s: any) => void }) {
  const inputs = useRef<(HTMLInputElement | null)[]>([]);

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) value = value.slice(0, 1);
    if (inputs.current[index]) inputs.current[index]!.value = value;
    if (value && index < 5) inputs.current[index + 1]?.focus();
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !inputs.current[index]?.value && index > 0) {
      inputs.current[index - 1]?.focus();
    }
  };

  return (
    <div className="flex-1 flex flex-col">
      <header className="flex items-center p-4">
        <button onClick={() => onNavigate('Register')} className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
          <ArrowLeft className="w-6 h-6" />
        </button>
      </header>

      <div className="flex-1 flex flex-col px-6 pt-4 pb-8">
        <div className="flex justify-center mb-8">
          <div className="w-20 h-20 rounded-2xl bg-primary/10 flex items-center justify-center text-primary relative">
            <Mail className="w-10 h-10" />
            <div className="absolute top-0 right-0 -mt-1 -mr-1 w-4 h-4 bg-primary rounded-full border-2 border-white"></div>
          </div>
        </div>

        <div className="text-center space-y-3 mb-10">
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Verificación de Correo</h1>
          <p className="text-slate-500">
            Te enviamos un código de 6 dígitos a tu correo <br/>
            <span className="font-medium text-slate-900">usuario@ejemplo.com</span>
          </p>
        </div>

        <div className="flex justify-between gap-2 mb-8">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <input
              key={i}
              ref={el => inputs.current[i] = el}
              type="number"
              className="w-12 h-14 sm:w-14 sm:h-16 text-center text-2xl font-bold rounded-xl bg-white border border-slate-200 focus:border-primary focus:ring-1 focus:ring-primary outline-none"
              onChange={(e) => handleChange(i, e.target.value)}
              onKeyDown={(e) => handleKeyDown(i, e)}
            />
          ))}
        </div>

        <div className="flex flex-col items-center gap-4 mb-auto">
          <div className="bg-slate-100 px-4 py-2 rounded-full text-sm font-medium text-slate-500">
            00:59
          </div>
          <p className="text-slate-500 text-sm">
            ¿No recibiste el código? <button className="text-primary font-bold">Reenviar código</button>
          </p>
        </div>

        <button onClick={() => onNavigate('ModeSelection')} className="w-full bg-primary text-white font-bold h-14 rounded-xl shadow-lg shadow-primary/30 active:scale-[0.98] transition-all">
          Verificar
        </button>
      </div>
    </div>
  );
}

export function ModeSelection({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col px-6 pt-4 pb-8">
      <header className="flex items-center justify-between py-5 mb-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-primary text-white flex items-center justify-center">
            <Store className="w-5 h-5" />
          </div>
          <h2 className="text-lg font-extrabold tracking-tight">GarageSale</h2>
        </div>
      </header>

      <div className="mb-8 text-center">
        <h1 className="text-3xl font-extrabold leading-tight tracking-tight mb-3">
          ¿Qué te trae por<br/>aquí hoy?
        </h1>
        <p className="text-slate-500 text-sm font-medium">
          Selecciona una opción para empezar tu viaje
        </p>
      </div>

      <div className="flex flex-col gap-5 flex-1 justify-center">
        <button onClick={() => onNavigate('Home')} className="group relative flex flex-col overflow-hidden rounded-2xl bg-white border-2 border-transparent hover:border-primary/50 shadow-sm hover:shadow-lg text-left w-full transition-all">
          <div className="w-full h-40 bg-indigo-50 relative overflow-hidden flex items-center justify-center">
            <Search className="w-24 h-24 text-primary/20 transform -rotate-12" />
            <div className="absolute top-4 right-4 bg-white p-2 rounded-full shadow-md text-primary">
              <Search className="w-5 h-5" />
            </div>
          </div>
          <div className="p-5 flex flex-col gap-1">
            <h3 className="text-xl font-bold group-hover:text-primary transition-colors">Quiero buscar un espacio</h3>
            <p className="text-slate-500 text-sm">Encuentra el lugar perfecto para vender tus cosas.</p>
          </div>
        </button>

        <button onClick={() => onNavigate('Home')} className="group relative flex flex-col overflow-hidden rounded-2xl bg-white border-2 border-transparent hover:border-primary/50 shadow-sm hover:shadow-lg text-left w-full transition-all">
          <div className="w-full h-40 bg-blue-50 relative overflow-hidden flex items-center justify-center">
            <HomeIcon className="w-24 h-24 text-primary/20 transform rotate-6" />
            <div className="absolute top-4 right-4 bg-white p-2 rounded-full shadow-md text-primary">
              <Store className="w-5 h-5" />
            </div>
          </div>
          <div className="p-5 flex flex-col gap-1">
            <h3 className="text-xl font-bold group-hover:text-primary transition-colors">Quiero alquilar mi garaje</h3>
            <p className="text-slate-500 text-sm">Publica tu espacio libre y gana dinero extra.</p>
          </div>
        </button>
      </div>
    </div>
  );
}
