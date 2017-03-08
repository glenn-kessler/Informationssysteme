/* Datum	2017-03-08
 *
 * Author	Glenn Keßler
 * 
 * Aufgabe	Steuern eines Gleichstrommotors anhand Benutzervorgabe und Drehzahlmessung
 * 
 * Funktionen	- Motor ansteuern, Vorwaerst, Rückwärts mit variabler Drehzahl
 * 		- Motordrehzahl erfassen
 * 		- Benutzereingabe erfassen
 * 		- Regelung der Motordrehzahl gemäß Benutzereingabe anhand erfasster Drehzahl
 * 		- Fahrt freigeben anhand Erkennung ob Passagier auf dem Board steht
 * 		- Fahrt freigeben anhand Erkennung ob Board auf dem Boden steht
 * 		- Fahrt freigeben anhand Erkennung ob Fernbedienung verbindung zum Arduino hat
 *
 */

	
/* Signale */
	const int D2_Hall_CLK = 2;
	const int D3_Hall_DATA = 3;
	const int D4_L298N_vor = 4;
	const int D5_L298N_zurueck = 5;
	const int D6_L298N_PWM = 6;
	int A1_Joystick_Y = A1;

/* Externer Interrupt */
	const unsigned short IRQ0 = 0;  // mappt auf Digital Pin 2 bzw. D2_Hall_CLK 

/* Speichervariablen */
	const unsigned int Anzahl_Magnete = 1;
	bool eine_ms_verstrichen = false;
	bool var_init = true;
	bool drehsinn = true;	// true = vorwaerts
	volatile unsigned int erkannte_Flanken = 0;	// inkrement durch externe ISR auf D2_Hall_CLK, Reset in Hautptprogramm
	volatile bool vorw_neu = true;
	volatile bool vorw_1 = true;
	volatile bool vorw_2 = true;	

	unsigned long letzter_Aufruf = 0;
	unsigned short Zykluszeit = 100 /* ms */;
	const short A1_Joystick_Y_offset = 249;	// verschiebt den Wertebereich nach -249 ... +255
	bool vz = true;
	int n=0, w=0, e=0, u=0;

void setup()
	{
	Serial.begin(9600);

	/* externer Interrupt um Hall-Switch zu lesen */
        attachInterrupt(IRQ0, isr_rpm, RISING);

        pinMode(D2_Hall_CLK, INPUT);
        pinMode(D3_Hall_DATA, INPUT);
	pinMode(D4_L298N_vor,OUTPUT);
	pinMode(D5_L298N_zurueck,OUTPUT);
	pinMode(D6_L298N_PWM,OUTPUT);

	/* interner Interrupt um gezählte Flanken nach einer eingestellten Zeit zu lesen */
	noInterrupts();           // deaktiviere Interrupts
	TCCR1A = 0;
	TCCR1B = 0;
	TCNT1  = 0;
	OCR1A = 6250;		// nach so vielen Ticks (=16*10^-6 s) soll die ISR aulsgelöst werden. Hier 1ms
	TCCR1B |= (1 << WGM12);   // Modus CTC
	TCCR1B |= (1 << CS12);    // Prescaler 256
	TIMSK1 |= (1 << OCIE1A);  // timer compare interrupt einschalten
	interrupts();             // aktiviere Interrupts
	}

void loop()
	{
	if( var_init )
		{

			var_init = false;
		}
	else if( ( millis() - letzter_Aufruf ) > Zykluszeit )
		{
			letzter_Aufruf = millis();
			vz = aktueller_drehsinn();
			n = gemessene_Drehzahl_mit_VZ_mit_Anpassung_an_Motortreiber( vz, erkannte_Flanken );
			w = Sollwert_aus_Fernbedienung_mit_Anpassung_an_Motortreiber();
			e = Regeldifferenz( w, n );
			u = PID_Regler( e );

			L298N_Ansteuerung( u );

			erkannte_Flanken = 0;
		}
	}

bool aktueller_drehsinn()
	{
                if( vorw_2 == true && vorw_1 == true && vorw_neu == true)
                        drehsinn = true;
                else if( vorw_2 == false && vorw_1 == false && vorw_neu == false)                                                                                          
                        drehsinn = false;

		return drehsinn;
	}

int gemessene_Drehzahl_mit_VZ_mit_Anpassung_an_Motortreiber( bool vz, int r )
	{
		if( vz == false )
			r = ~r+1;

		/* Die maximale gemessene Drehzahl beträgt in beiden Drehrichtungen
		 * 0...72
		 * 
		 *
		 * der sich Wertebereich des Motortreibers in beiden Richtungen beträgt
		 * 0...255 
		 * 
		 * der Faktor von 72 auf 255 beträgt
		 * 3,5416
		 */

		 return ( n * 354 ) / 100;
	}

int Sollwert_aus_Fernbedienung_mit_Anpassung_an_Motortreiber()
	{
		/* gemessene maximale Drehzahl = 72
		 * 
		 * diese ist in beiden Fahrtrichtungen möglich
		 * d.h.
		 * der Wertebereich des 10Bit Wertes aus dem analogen Eingang 
		 * muss auf einen Wertebereich zwischen -72 und +72 aufgeteilt werden
		 *
		 * (72+1)*2 * x = 1024 ---> x = 7,01369
		 *
		 * also so ungefähr 7
		 *
		 * Da die Werte des Analogeinganges alle im Positiven Bereich liegen
		 * muss dieser noch verschoben werden, so dass die Mitte des Wertebereichs
		 * auch wirklich eine Vorgabe von 0 liefert
		 * 
		 */
		int x = 7;
		int Verschiebung = 73;
	 	return ( analogRead( A1_Joystick_Y ) / 7 ) - Verschiebung;
	}

/* belässt den vorigen Drehsinn unverändert wenn nicht die letzten drei Messungen das selbe Ergebnis hatten */
int Regeldifferenz( int w, int n)
	{
	return w - n;
	}

int PID_Regler( int e )
	{
	const int kP = 1;	// P-Anteil	
	const int kI = 1;	// I-Anteil	kI = kP * T/Tn
	const int kD = 0;	// D-Anteil	kD = Tv/T

	int u;

	static int uI = 0;	
	static int ek_1 = 0;	// Regeldifferenz d. vorigen Abtastung

	uI += kI*e;		// I-Anteil

	u = kP*e + uI + kD*(e - ek_1);

	ek_1 = e;		// zuw. d. aktuellen Wertes von e f. nexten Durchlauf

	return u;
	}

void L298N_Ansteuerung( int Stellwert )
	{
	if( Stellwert < 0 )
		{	
		digitalWrite(D5_L298N_zurueck,HIGH);
		digitalWrite(D4_L298N_vor,LOW);

		analogWrite( D6_L298N_PWM, ( ~Stellwert + 1 ) ); // Invertieren des Stellwertes liefert den Betrag -1.
		}
	else
		{
		digitalWrite(D5_L298N_zurueck,LOW);
		digitalWrite(D4_L298N_vor,HIGH);

		analogWrite( D6_L298N_PWM, Stellwert );
		}
	}

int Flanken_auswerten(unsigned int erkannte_Flanken )
        {
                return erkannte_Flanken * 60 * 10 / Anzahl_Magnete ;
        }

void isr_rpm()
        {   
        erkannte_Flanken++;

        vorw_2 = vorw_1;
        vorw_1 = vorw_neu;

	if( !digitalRead(D3_Hall_DATA) == 1 )	
                vorw_neu = true;
        else
                vorw_neu = false;
        }

ISR(TIMER1_COMPA_vect)          // timer compare interrupt service routine
	{
	eine_ms_verstrichen = true;
	}
