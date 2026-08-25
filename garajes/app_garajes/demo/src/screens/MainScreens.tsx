import React from 'react';
import { Search, MapPin, Calendar, ChevronRight, List, Compass, Heart, PlusCircle, MessageCircle, User, ArrowLeft, SlidersHorizontal, Star, Wifi, Zap, Coffee, Share } from 'lucide-react';

export function Home({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col relative bg-slate-100">
      <div className="bg-white rounded-b-[2rem] shadow-sm z-10 pb-6 relative">
        <div className="flex items-center justify-between px-6 pt-12 pb-4">
          <div>
            <span className="text-sm text-slate-500">Hola, Sara</span>
            <h2 className="text-2xl font-bold text-slate-900 mt-0.5">Encuentra tu espacio</h2>
          </div>
          <div className="w-10 h-10 rounded-full bg-rose-200 flex items-center justify-center relative overflow-hidden">
            <User className="text-rose-400 w-6 h-6" />
            <div className="absolute top-1 right-1 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></div>
          </div>
        </div>

        <div className="px-6 space-y-3">
          <div className="flex items-center bg-slate-50 rounded-xl px-4 h-12">
            <Search className="text-primary w-5 h-5 mr-3" />
            <input type="text" placeholder="Ubicación o Código Postal" className="bg-transparent border-none outline-none w-full text-sm" />
            <button className="p-1 rounded-full hover:bg-slate-200">
              <MapPin className="text-slate-400 w-5 h-5" />
            </button>
          </div>
          <button className="w-full flex items-center justify-between bg-slate-50 rounded-xl px-4 h-12">
            <div className="flex items-center">
              <Calendar className="text-primary w-5 h-5 mr-3" />
              <span className="text-sm text-slate-700">Seleccionar Fechas</span>
            </div>
            <ChevronRight className="text-slate-400 w-5 h-5" />
          </button>
        </div>

        <div className="pt-6">
          <h3 className="px-6 text-base font-bold mb-3">¿Qué vas a vender?</h3>
          <div className="flex overflow-x-auto no-scrollbar gap-3 px-6 pb-2">
            <button className="flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-full whitespace-nowrap shadow-md shadow-primary/30">
              <span className="text-sm font-medium">Ropa</span>
            </button>
            <button className="flex items-center gap-2 px-5 py-2.5 bg-slate-50 text-slate-600 rounded-full whitespace-nowrap">
              <span className="text-sm font-medium">Electrónica</span>
            </button>
            <button className="flex items-center gap-2 px-5 py-2.5 bg-slate-50 text-slate-600 rounded-full whitespace-nowrap">
              <span className="text-sm font-medium">Muebles</span>
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 relative overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800')] bg-cover bg-center opacity-20"></div>
        
        <div className="absolute top-[20%] left-[30%]">
          <div className="bg-white px-3 py-1.5 rounded-lg font-bold text-xs shadow-md relative">
            $25/d
            <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white rotate-45"></div>
          </div>
        </div>
        
        <div className="absolute top-[40%] left-[50%] z-10">
          <div className="bg-primary text-white px-4 py-2 rounded-xl font-bold text-sm shadow-xl relative animate-bounce">
            $45/d
            <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-primary rotate-45"></div>
          </div>
        </div>

        <div className="absolute top-[60%] left-[60%]">
          <div className="bg-white px-3 py-1.5 rounded-lg font-bold text-xs shadow-md relative">
            $18/d
            <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white rotate-45"></div>
          </div>
        </div>

        <button onClick={() => onNavigate('SearchResults')} className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-slate-900 text-white px-5 py-2.5 rounded-full shadow-xl flex items-center gap-2 z-20">
          <List className="w-5 h-5" />
          <span className="text-sm font-medium">Ver Lista</span>
        </button>
      </div>

      <nav className="bg-white px-6 pb-8 pt-4 shadow-[0_-4px_20px_rgba(0,0,0,0.05)] z-30 flex justify-between items-end">
        <button className="flex flex-col items-center gap-1 w-14">
          <div className="bg-primary w-8 h-8 rounded-full flex items-center justify-center shadow-sm">
            <Compass className="text-white w-5 h-5" />
          </div>
          <span className="text-[10px] font-bold text-primary">Explorar</span>
        </button>
        <button className="flex flex-col items-center gap-1 w-14 text-slate-400">
          <Heart className="w-6 h-6" />
          <span className="text-[10px] font-medium">Guardados</span>
        </button>
        <button className="flex flex-col items-center gap-1 w-14">
          <div className="bg-primary/10 w-10 h-10 flex items-center justify-center rounded-xl mb-1">
            <PlusCircle className="text-primary w-6 h-6" />
          </div>
        </button>
        <button className="flex flex-col items-center gap-1 w-14 text-slate-400 relative">
          <MessageCircle className="w-6 h-6" />
          <div className="absolute top-0 right-3 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></div>
          <span className="text-[10px] font-medium">Mensajes</span>
        </button>
        <button className="flex flex-col items-center gap-1 w-14 text-slate-400">
          <User className="w-6 h-6" />
          <span className="text-[10px] font-medium">Perfil</span>
        </button>
      </nav>
    </div>
  );
}

export function SearchResults({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col relative bg-slate-100">
      <header className="absolute top-0 left-0 right-0 z-20 px-4 pt-12 pb-4 pointer-events-none">
        <div className="pointer-events-auto flex items-center gap-3">
          <button onClick={() => onNavigate('Home')} className="w-10 h-10 bg-white rounded-full shadow-md flex items-center justify-center">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="flex-1 bg-white rounded-full shadow-md flex items-center px-4 h-10">
            <Search className="text-primary w-4 h-4 mr-2" />
            <span className="text-sm text-slate-600">Polanco, CDMX</span>
          </div>
        </div>
      </header>

      <div className="h-[45vh] relative overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800')] bg-cover bg-center opacity-30"></div>
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-10">
          <button className="flex items-center gap-2 bg-primary text-white px-5 py-2.5 rounded-full shadow-lg font-semibold text-sm">
            <SlidersHorizontal className="w-4 h-4" />
            Filtros
          </button>
        </div>
      </div>

      <div className="flex-1 bg-white rounded-t-3xl shadow-[0_-4px_20px_rgba(0,0,0,0.1)] z-10 flex flex-col -mt-4">
        <div className="w-full flex justify-center pt-3 pb-1">
          <div className="w-12 h-1.5 bg-slate-300 rounded-full"></div>
        </div>
        
        <div className="flex-1 overflow-y-auto px-4 pb-6 pt-2">
          <div className="flex justify-between items-baseline mb-4 px-1">
            <h2 className="text-lg font-bold">32 Garages disponibles</h2>
            <span className="text-xs text-slate-500">Relevancia</span>
          </div>

          <div onClick={() => onNavigate('GarageDetails')} className="bg-white rounded-xl p-3 shadow-sm border border-primary/20 mb-4 flex gap-3 cursor-pointer">
            <div className="relative w-24 h-24 rounded-lg overflow-hidden">
              <img src="https://images.unsplash.com/photo-1605810230434-7631ac76ec81?auto=format&fit=crop&q=80&w=400" alt="Garage" className="w-full h-full object-cover" />
              <div className="absolute top-1 left-1 bg-white/90 px-1.5 py-0.5 rounded text-[10px] font-bold flex items-center gap-0.5">
                <Star className="w-3 h-3 text-orange-400 fill-orange-400" /> 4.9
              </div>
            </div>
            <div className="flex flex-col flex-1 justify-between py-0.5">
              <div>
                <div className="flex justify-between items-start">
                  <h3 className="font-bold text-sm leading-tight">Garage Amplio Polanco</h3>
                  <Heart className="w-4 h-4 text-slate-400" />
                </div>
                <p className="text-xs text-slate-500 mt-1">Calle Arquímedes 15</p>
              </div>
              <div className="flex items-end justify-between mt-2">
                <div className="flex gap-1.5 text-primary">
                  <Wifi className="w-4 h-4" />
                  <Coffee className="w-4 h-4" />
                  <Zap className="w-4 h-4" />
                </div>
                <div className="text-right">
                  <span className="block text-[10px] text-slate-400 uppercase">desde</span>
                  <div className="text-primary font-bold text-lg leading-none">$450 <span className="text-xs font-normal text-slate-500">/día</span></div>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-3 shadow-sm border border-slate-100 mb-4 flex gap-3">
            <div className="relative w-24 h-24 rounded-lg overflow-hidden">
              <img src="https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80&w=400" alt="Garage" className="w-full h-full object-cover" />
              <div className="absolute top-1 left-1 bg-white/90 px-1.5 py-0.5 rounded text-[10px] font-bold flex items-center gap-0.5">
                <Star className="w-3 h-3 text-orange-400 fill-orange-400" /> 4.5
              </div>
            </div>
            <div className="flex flex-col flex-1 justify-between py-0.5">
              <div>
                <div className="flex justify-between items-start">
                  <h3 className="font-bold text-sm leading-tight">Cochera Techada Anzures</h3>
                  <Heart className="w-4 h-4 text-slate-400" />
                </div>
                <p className="text-xs text-slate-500 mt-1">Gutenberg 45</p>
              </div>
              <div className="flex items-end justify-between mt-2">
                <div className="flex gap-1.5 text-primary">
                  <Zap className="w-4 h-4" />
                </div>
                <div className="text-right">
                  <span className="block text-[10px] text-slate-400 uppercase">desde</span>
                  <div className="text-primary font-bold text-lg leading-none">$250 <span className="text-xs font-normal text-slate-500">/día</span></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export function GarageDetails({ onNavigate }: { onNavigate: (s: any) => void }) {
  return (
    <div className="flex-1 flex flex-col relative bg-white">
      <div className="flex-1 overflow-y-auto pb-24 no-scrollbar">
        <div className="relative w-full aspect-[4/3]">
          <div className="absolute top-0 left-0 right-0 z-10 flex justify-between items-center p-4 pt-12 bg-gradient-to-b from-black/60 to-transparent">
            <button onClick={() => onNavigate('SearchResults')} className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center">
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div className="flex gap-2">
              <button className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center">
                <Share className="w-5 h-5" />
              </button>
              <button className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center">
                <Heart className="w-5 h-5" />
              </button>
            </div>
          </div>
          <img src="https://images.unsplash.com/photo-1605810230434-7631ac76ec81?auto=format&fit=crop&q=80&w=800" alt="Garage" className="w-full h-full object-cover" />
        </div>

        <div className="px-5 -mt-6 relative z-10">
          <div className="bg-white rounded-xl shadow-lg p-5 mb-6 border border-slate-100">
            <div className="flex justify-between items-start mb-2">
              <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-primary/10 text-primary">
                Garaje Privado
              </span>
              <div className="flex flex-col items-end">
                <span className="text-xl font-bold text-primary">$20</span>
                <span className="text-xs text-slate-500">por hora</span>
              </div>
            </div>
            <h1 className="text-2xl font-bold leading-tight mb-2">Garage Espacioso en Palermo</h1>
            <div className="flex items-center text-slate-500 text-sm mb-4">
              <MapPin className="w-4 h-4 mr-1 text-primary" />
              Av. Santa Fe 1234, CABA
            </div>
            <div className="h-px bg-slate-100 w-full mb-4"></div>
            
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-slate-200 overflow-hidden">
                  <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150" alt="Host" className="w-full h-full object-cover" />
                </div>
                <div>
                  <p className="text-sm font-semibold">Maria G.</p>
                  <p className="text-xs text-slate-500">Dueña del Garaje</p>
                </div>
              </div>
              <div className="flex items-center gap-1 bg-yellow-50 px-2 py-1 rounded-lg">
                <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                <span className="text-xs font-bold text-slate-700">4.8</span>
                <span className="text-xs text-slate-400">(24)</span>
              </div>
            </div>
          </div>

          <div className="mb-8">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span className="w-1 h-5 bg-primary rounded-full"></span>
              Incluido gratis
            </h2>
            <div className="grid grid-cols-3 gap-3">
              <div className="flex flex-col items-center p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary mb-2">
                  <User className="w-5 h-5" />
                </div>
                <span className="text-xs font-medium">Baño</span>
              </div>
              <div className="flex flex-col items-center p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary mb-2">
                  <Zap className="w-5 h-5" />
                </div>
                <span className="text-xs font-medium">Luz</span>
              </div>
              <div className="flex flex-col items-center p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary mb-2">
                  <Wifi className="w-5 h-5" />
                </div>
                <span className="text-xs font-medium">WiFi</span>
              </div>
            </div>
          </div>

          <div className="mb-6">
            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
              <span className="w-1 h-5 bg-primary rounded-full"></span>
              Servicios Extra
            </h2>
            <div className="flex flex-col gap-3">
              <label className="flex items-center p-4 rounded-xl border border-slate-200 shadow-sm cursor-pointer">
                <input type="checkbox" className="w-5 h-5 rounded border-slate-300 text-primary focus:ring-primary" />
                <div className="ml-4 flex-1">
                  <div className="flex justify-between items-center">
                    <span className="font-semibold text-sm">Alquiler de mesa</span>
                    <span className="font-bold text-primary text-sm">+$5.00</span>
                  </div>
                  <p className="text-xs text-slate-500 mt-1">Mesa plegable 2x1m</p>
                </div>
              </label>
              <label className="flex items-center p-4 rounded-xl border border-primary/50 bg-primary/5 shadow-sm cursor-pointer">
                <input type="checkbox" defaultChecked className="w-5 h-5 rounded border-slate-300 text-primary focus:ring-primary" />
                <div className="ml-4 flex-1">
                  <div className="flex justify-between items-center">
                    <span className="font-semibold text-sm">Perchero móvil</span>
                    <span className="font-bold text-primary text-sm">+$3.00</span>
                  </div>
                  <p className="text-xs text-slate-500 mt-1">Para colgar ropa</p>
                </div>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-slate-100 p-4 pb-8 z-50 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
        <div className="flex items-center justify-between gap-4">
          <div className="flex flex-col">
            <span className="text-xs text-slate-500 font-medium">Total Estimado</span>
            <div className="flex items-baseline gap-1">
              <span className="text-2xl font-extrabold tracking-tight">$45.00</span>
              <span className="text-xs text-slate-400 line-through">$52.00</span>
            </div>
          </div>
          <button onClick={() => onNavigate('BookingRequest')} className="flex-1 bg-primary text-white font-bold py-3.5 px-6 rounded-xl shadow-lg shadow-primary/30 flex items-center justify-center gap-2">
            Siguiente
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
