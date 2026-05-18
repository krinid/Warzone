require('Utilities')


function Client_SaveConfigureUI(alert)

  
--Pure AI
--Attack
   Mod.Settings.P_attack = PP_attack.GetIsChecked() 
    
--block
Mod.Settings.P_block = PP_block.GetIsChecked() 
--city
Mod.Settings.P_city = PP_city.GetIsChecked() 
--pure deploy
Mod.Settings.P_deploy = PP_deploy.GetIsChecked() 
--pure diplo
Mod.Settings.P_diplo = PP_diplo.GetIsChecked() 
--pure emergency
Mod.Settings.P_emergency = PP_emger.GetIsChecked() 
--pure Reinforcement
Mod.Settings.P_rein = PP_rein.GetIsChecked() 
--human bomb
Mod.Settings.P_bomb = PP_bomb.GetIsChecked() 

-- Human AI
--Attack
Mod.Settings.H_attack = HH_attack.GetIsChecked() 
    
--block
Mod.Settings.H_block = HH_block.GetIsChecked() 
--city
Mod.Settings.H_city = HH_city.GetIsChecked() 
--pure deploy
Mod.Settings.H_deploy = HH_deploy.GetIsChecked() 
--pure diplo
Mod.Settings.H_diplo = HH_diplo.GetIsChecked() 
--pure emergency
Mod.Settings.H_emergency = HH_emger.GetIsChecked() 
--pure Reinforcement
Mod.Settings.H_rein = HH_rein.GetIsChecked() 
--human bomb
Mod.Settings.H_bomb = HH_bomb.GetIsChecked() 
end
