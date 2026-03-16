/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState } from 'react';
import { Onboarding, AuthMethod, Register, OTPVerification, ModeSelection } from './screens/AuthScreens';
import { Home, SearchResults, GarageDetails } from './screens/MainScreens';
import { BookingRequest, ChatPayment, Rating } from './screens/BookingScreens';

export type Screen = 'Onboarding' | 'AuthMethod' | 'Register' | 'OTPVerification' | 'ModeSelection' | 'Home' | 'SearchResults' | 'GarageDetails' | 'BookingRequest' | 'ChatPayment' | 'Rating';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('Onboarding');

  const navigate = (screen: Screen) => setCurrentScreen(screen);

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 font-sans selection:bg-primary/20 selection:text-primary flex justify-center">
      <div className="w-full max-w-md bg-white min-h-screen shadow-2xl relative overflow-hidden flex flex-col">
        {currentScreen === 'Onboarding' && <Onboarding onNavigate={navigate} />}
        {currentScreen === 'AuthMethod' && <AuthMethod onNavigate={navigate} />}
        {currentScreen === 'Register' && <Register onNavigate={navigate} />}
        {currentScreen === 'OTPVerification' && <OTPVerification onNavigate={navigate} />}
        {currentScreen === 'ModeSelection' && <ModeSelection onNavigate={navigate} />}
        {currentScreen === 'Home' && <Home onNavigate={navigate} />}
        {currentScreen === 'SearchResults' && <SearchResults onNavigate={navigate} />}
        {currentScreen === 'GarageDetails' && <GarageDetails onNavigate={navigate} />}
        {currentScreen === 'BookingRequest' && <BookingRequest onNavigate={navigate} />}
        {currentScreen === 'ChatPayment' && <ChatPayment onNavigate={navigate} />}
        {currentScreen === 'Rating' && <Rating onNavigate={navigate} />}
      </div>
    </div>
  );
}
