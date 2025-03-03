rec {
  name = "relaxing-random-entropy";
  patch = builtins.toFile name ''
    --- a/drivers/char/random.c
    +++ b/drivers/char/random.c
    @@ -1280,8 +1280,6 @@
     		last = stack->entropy;
     	}
     	stack->samples_per_bit = DIV_ROUND_UP(NUM_TRIAL_SAMPLES, num_different + 1);
    -	if (stack->samples_per_bit > MAX_SAMPLES_PER_BIT)
    -		return;
     
     	atomic_set(&stack->samples, 0);
     	timer_setup_on_stack(&stack->timer, entropy_timer, 0);
  '';
}
