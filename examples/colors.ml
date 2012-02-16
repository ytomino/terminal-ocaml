for concealed = 0 to 1 do
	for reverse = 0 to 1 do
		for blink = 0 to 1 do
			for underscore = 0 to 1 do
				for bold = 0 to 1 do
					for bg_intensity = 0 to 1 do
						for bg_blue = 0 to 1 do
							for bg_green = 0 to 1 do
								for bg_red = 0 to 1 do
									for intensity = 0 to 1 do
										for blue = 0 to 1 do
											for green = 0 to 1 do
												for red = 0 to 1 do
													Terminal.color
														stdout
														~reset:true
														~foreground:{
															Terminal.red;
															green;
															blue;
															intensity}
														~background:{
															Terminal.red = bg_red;
															green = bg_green;
															blue = bg_blue;
															intensity = bg_intensity}
														~bold:(bold <> 0)
														~underscore:(underscore <> 0)
														~blink:(blink <> 0)
														~reverse:(reverse <> 0)
														~concealed:(concealed <> 0)
														();
													print_char 'A'
												done
											done
										done
									done
								done
							done
						done
					done;
					Terminal.color stdout ~reset:true ();
					print_newline ()
				done
			done
		done
	done
done;;
