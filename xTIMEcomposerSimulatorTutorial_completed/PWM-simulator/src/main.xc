#include <platform.h>
#include <xs1.h>
#include "pwm_tutorial_example.h"

out port p_led = on tile[1]:XS1_PORT_4A;

void pwm_controller(chanend c_pwm)
{
	// send the PWM period length
	c_pwm <: 1000;

	// send the PWM duty cycle length
	c_pwm <: 500;
}

int main() {
	chan c_pwm_duty;
	par {
		on tile[1]: {
			pwm_tutorial_example(c_pwm_duty, p_led, 4);
		}
		on tile[1]: {
			pwm_controller(c_pwm_duty);
		}
	}
	return 0;
}
