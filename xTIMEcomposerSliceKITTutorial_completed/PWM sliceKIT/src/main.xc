#include <platform.h>
#include <xs1.h>
#include "pwm_tutorial_example.h"
#include "i2c.h"
#include "print.h"
out port p_led = on tile[1]:XS1_PORT_4A;

on tile[1] : struct r_i2c i2cOne = {
		XS1_PORT_1F, XS1_PORT_1B, 1000
};


void wait(unsigned wait_cycles) {
	timer tmr;
	unsigned t;

	tmr :> t;

	tmr when timerafter (t+wait_cycles) :> void;
}

int TEMPERATURE_LUT[][2]= //Temperature Look up table
{
  {-10,845},{-5,808},{0,765},{5,718},{10,668},
  {15,614},{20,559},{25,504},{30,450},{35,399},
  {40,352},{45,308},{50,269},{55,233},{60,202}
};

int linear_interpolation(int adc_value)
{
  int i=0,x1,y1,x2,y2,temper;
  while(adc_value<TEMPERATURE_LUT[i][1])
  {
    i++;
  }
  // Calculating Linear interpolation using the formula
  // y=y1+(x-x1)*(y2-y1)/(x2-x1)
  x1=TEMPERATURE_LUT[i-1][1];
  y1=TEMPERATURE_LUT[i-1][0];
  x2=TEMPERATURE_LUT[i][1];
  y2=TEMPERATURE_LUT[i][0];
  temper=y1+(((adc_value-x1)*(y2-y1))/(x2-x1));

  return temper;
}


void pwm_controller(chanend c_pwm)
{
	int period = 1000;
	int duty_cycle = 1000;
	unsigned step = period / 100;
	int delta = -step;

	unsigned char wr_data[1]={0x13};
	unsigned char rd_data[2];
	int adc_value;
	i2c_master_write_reg(0x28, 0x00, wr_data, 1, i2cOne);

	printstr("Welcome to the XMOS PWM tutorial\n");

	c_pwm <: period;
	c_pwm <: duty_cycle;
	while(1) {
		c_pwm <: duty_cycle;
		wait(XS1_TIMER_HZ/100);
		duty_cycle += delta;

		if (duty_cycle > period)
		{
		    //Read ADC value using I2C read

		    rd_data[0]=rd_data[0]&0x0F;
		    i2c_master_rx(0x28, rd_data, 2, i2cOne);
		    rd_data[0]=rd_data[0]&0x0F;
		    adc_value=(rd_data[0]<<6)|(rd_data[1]>>2);
		    printstr("Temperature is :");
		    printintln(linear_interpolation(adc_value));


			delta = -step;
			duty_cycle = period;
		}
		else if(duty_cycle < 0) {
			delta = step;
			duty_cycle = 0;
		}
	}

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
