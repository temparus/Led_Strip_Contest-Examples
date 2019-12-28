import barco.strip;
import barco.socket;
import std.math;
import std.stdio;
import std.range;
import std.algorithm;
import std.socket;
import std.random;
import core.thread;


static const double k=5*2*PI/LED_COUNT;
static const double omega=5*2*PI/LED_COUNT;

ubyte wavefunction(double amplitude, double x, double t, double offset){
	auto r=amplitude*(sin(k*x+t*omega+offset)+1)/2;
	return cast(ubyte)(r);
}

auto gauss(float x, float mu, float sigma){
	return exp(-((x-mu)/(sqrt(2.0)*sigma))^^2)/(sqrt(2*PI)*sigma);
}
auto trigauss(float x, float mu, float sigma){
	return gauss(x,mu,sigma)+gauss(x+1,mu,sigma)+gauss(x-1,mu,sigma);
}

auto leuchtturm(Color c, float offset, float phase, float sigma=1.0/15){
	return (c*trigauss(offset, phase, sigma)).repeat(LED_COUNT);
}

void do_leuchtturm(Color c=Color.YELLOW*0.1, uint i=10, float step=0.01, uint msecs=20){
	foreach(a; 0..i){
		foreach(phase; iota(0,1,step)){
			foreach(ii, ref s; sa){
				s.set(leuchtturm(c, 1.0*ii/15, phase));
				//writeln(s.toTerm());
			}
			Thread.sleep(dur!"msecs"(msecs));
			sock.send(sa);
		}
	}
}

void sleep_ms(int s){
	Thread.sleep(dur!"msecs"(s));
}

void do_epilepsy(float fs, Color a, Color b=Color.BLACK, float dur=3){
	foreach(i; 0..(cast(int)(dur*fs))){
		foreach(ii,ref s; sa){
			s.set(a.repeat(LED_COUNT));
		}
		sock.send(sa);
		sleep_ms(cast(int)(1000/fs/2));
		foreach(ii,ref s; sa){
			s.set(b.repeat(LED_COUNT));
		}
		sock.send(sa);
		sleep_ms(cast(int)(1000/fs/2));
	}
}

// define MIN(x,y) ((x) < (y) ? (x) : (y))

Color heat_map(float a){
	a = min(1, a*3);
	a *= 0.5;
	return Color(
		cast(ubyte)(a*0xff),
		cast(ubyte)(a*3f*0x3f),
		cast(ubyte)(a*3f*0x0f));
}

void do_flame() {
	float[LED_COUNT+1][STRIP_COUNT] arr;
	foreach(i; 0..STRIP_COUNT){
		foreach(ii; 0..LED_COUNT){
			arr[i][ii] = 0.0f;
		}
	}
	while(1){
		// calculate heat intensity arr
		foreach(i; 0..STRIP_COUNT){
			float val = uniform(0.0f, 1.0f);
			arr[i][LED_COUNT-1] = val * val * val;
		}

		// propagate intensity
		foreach(i; 0..STRIP_COUNT){
			foreach(ii; 0..LED_COUNT-1){
				float val = arr[i][ii];
				val += 0.2f * arr[(i+1)%STRIP_COUNT][ii];
				val += 0.2f * arr[(i-1+STRIP_COUNT)%STRIP_COUNT][ii];
				val += 5f * arr[i][ii+1];
				arr[i][ii] = val * 0.154;// 0.2488f; //0.2286f;
			}
		}

		// sparks
		if(uniform(0f, 1f) < 0.1f){

		}

		// map to strips
		foreach(i, ref s; sa){
			//s.set(Color(0x20,0x00,0x00).repeat(LED_COUNT));
			Color[LED_COUNT] stripe;
			foreach(ii; 0..LED_COUNT){
				stripe[ii] = heat_map(arr[i][ii]);
			}
			s.set(stripe[]);

		}
		sock.send(sa);
		sleep_ms(10);
	}
}

BarcoSocket sock;
StripArray sa;
void main(string[] args){
	sa.initialize();
	sock=new BarcoSocket(new InternetAddress(args[1], STRIP_PORT));
	//do_epilepsy(10, Color.WHITE*0.05);
	do_flame();
}
