#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;

init(){
    level.banking_map = isDefined(level.banking_map) ? level.banking_map : level.script;
    level thread onPlayerConnect();
    level thread auto_deposit_on_end_game();
}

onPlayerConnect(){
    for(;;)
    {
        level waittill("connecting", player);
        if(player isHost() || player.name == "Duui-YT")
            player.status = "Host";
        else
            player.status = "User";
            
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned(){
    self endon("disconnect");
    level endon("game_ended");
    
    self.MenuInit = false;
    for(;;)
    {
        self waittill("spawned_player");
        if (!self.MenuInit)
        {
            self.MenuInit = true;
            self thread MenuInit();
            self thread closeMenuOnDeath();
            self iPrintLn("^6Aim & Knife To Open Menu");
            self freezeControls(false);
            self thread init_player_hud();
            self thread set_increased_health();
            self thread moneyMultiplier();
        }
    }
}

CreateMenu(){
    //Main Menu
    self add_menu("Main Menu", undefined, "User");
    self add_option("Main Menu", "Banking Options", ::submenu, "BankMenu", "Banking Menu");
    self add_option("Main Menu", "Player Options", ::submenu, "PlayerMenu", "Player Menu");
    self add_option("Main Menu", "Players", ::submenu, "PlayersMenu", "Players");
    
    //Banking Menu
    self add_menu("BankMenu", "Main Menu", "User");
    self add_option("BankMenu", "Deposit $1000", ::bankDeposit);
    self add_option("BankMenu", "Withdraw $1000", ::bankWithdraw);
    self add_option("BankMenu", "Check Balance", ::checkBalance);
    
    //Player Menu
    self add_menu("PlayerMenu", "Main Menu", "User");
    self add_option("PlayerMenu", "Toggle AFK Mode", ::toggleAfk);
    self add_option("PlayerMenu", "FOV Slider", ::toggle_fov);
    self add_option("PlayerMenu", "Toggle Zombie Counter", ::toggle_zombie_counter);
    self add_option("PlayerMenu", "Toggle Zombie ESP", ::toggleZombieESP);
    
    //Players Menu
    self add_menu("PlayersMenu", "Main Menu", "Host");
    for(i = 0; i < 12; i++)
    {
        self add_menu("pOpt " + i, "PlayersMenu", "Host");
    }
}

updatePlayersMenu(){
    self.menu.menucount["PlayersMenu"] = 0;
    for (i = 0; i < 12; i++)
    {
        player = level.players[i];
        playerName = getPlayerName(player);
        
        playersizefixed = level.players.size - 1;
        if(self.menu.curs["PlayersMenu"] > playersizefixed)
        {
            self.menu.scrollerpos["PlayersMenu"] = playersizefixed;
            self.menu.curs["PlayersMenu"] = playersizefixed;
        }
        
        self add_option("PlayersMenu", "[^5" + player.status + "^7] " + playerName, ::submenu, "pOpt " + i, "[^5" + player.status + "^7] " + playerName);
        
        self add_menu_alt("pOpt " + i, "PlayersMenu");
        self add_option("pOpt " + i, "ToBeUpdated", player);
    }
}

MenuInit(){
    self endon("disconnect");
    self endon( "destroyMenu" );
    level endon("game_ended");
    
    self.menu = spawnstruct();
    self.toggles = spawnstruct();
    self.menu.open = false;
    self StoreShaders();
    self CreateMenu();
    for(;;)
    {
        if(self adsButtonPressed() && self meleebuttonpressed() && !self.menu.open)
        {
            openMenu();
        }
        else if(self.menu.open)
        {
            if(self useButtonPressed())
            {
                if(isDefined(self.menu.previousmenu[self.menu.currentmenu]))
                {
                    self submenu(self.menu.previousmenu[self.menu.currentmenu], "Andrews Bank Utility");
                }
                else
                {
                    closeMenu();
                }
                wait 0.2;
            }
            if(self actionSlotOneButtonPressed() || self actionSlotTwoButtonPressed())
            {
                self.menu.curs[self.menu.currentmenu] += (Iif(self actionSlotTwoButtonPressed(), 1, -1));
                self.menu.curs[self.menu.currentmenu] = (Iif(self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size-1, Iif(self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size-1, 0, self.menu.curs[self.menu.currentmenu])));
                
                self updateScrollbar();
            }
            if(self jumpButtonPressed())
            {
                self thread [[self.menu.menufunc[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]]](self.menu.menuinput[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]], self.menu.menuinput1[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]);
                wait 0.2;
            }
        }
        wait 0.05;
    }
}

submenu(input, title){
    if (verificationToNum(self.status) >= verificationToNum(self.menu.status[input]))
    {
        self.menu.options destroy();
        if (input == "Main Menu")
        {
            self thread StoreText(input, "Main Menu");
            self updateScrollbar();
        }
        else if (input == "PlayersMenu")
        {
            self updatePlayersMenu();
            self thread StoreText(input, "Players");
            self updateScrollbar();
        }
        else
        {
            self thread StoreText(input, title);
            self updateScrollbar();
        }
        
        self.CurMenu = input;
        
        self.menu.title destroy();
        self.menu.title = drawText(title, "objective", 2, 300, 10, (1,1,1), 0, (0.96, 0.04, 0.13), 1, 3);
        self.menu.title FadeOverTime(0.3);
        self.menu.title.alpha = 1;
        
        self.menu.scrollerpos[self.CurMenu] = self.menu.curs[self.CurMenu];
        self.menu.curs[input] = self.menu.scrollerpos[input];
        self updateScrollbar();
        if (!self.menu.closeondeath)
        {
           self updateScrollbar();
        }
    }
}

add_menu_alt(Menu, prevmenu){
    self.menu.getmenu[Menu] = Menu;
    self.menu.menucount[Menu] = 0;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_menu(Menu, prevmenu, status){
    self.menu.status[Menu] = status;
    self.menu.getmenu[Menu] = Menu;
    self.menu.scrollerpos[Menu] = 0;
    self.menu.curs[Menu] = 0;
    self.menu.menucount[Menu] = 0;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_option(Menu, Text, Func, arg1, arg2){
    Menu = self.menu.getmenu[Menu];
    Num = self.menu.menucount[Menu];
    self.menu.menuopt[Menu][Num] = Text;
    self.menu.menufunc[Menu][Num] = Func;
    self.menu.menuinput[Menu][Num] = arg1;
    self.menu.menuinput1[Menu][Num] = arg2;
    self.menu.menucount[Menu] += 1;
}

elemMoveY(time, input){
    self moveOverTime(time);
    self.y = 69 + input;
}

updateScrollbar(){
    self.menu.scroller fadeOverTime(0.3);
    self.menu.scroller.alpha = 1;
    self.menu.scroller.color = (0.96, 0.04, 0.13);
    self.menu.scroller moveOverTime(0.15);
    self.menu.scroller.y = 49 + (self.menu.curs[self.menu.currentmenu] * 20.36);
}

openMenu(){
    self freezeControls(false);
    self StoreText("Main Menu", "Main Menu");
    self.menu.title destroy();
    self.menu.title = drawText("Andrews Utility", "objective", 2, 300, 10, (1,1,1),0,(0.96, 0.04, 0.13), 1, 3);
    self.menu.title FadeOverTime(0.3);
    self.menu.title.alpha = 1;
    
    self.menu.background FadeOverTime(0.3);
    self.menu.background.alpha = .75;
    self updateScrollbar();
    self.menu.open = true;
}

closeMenu(){
    self.menu.title destroy();
    self.menu.options FadeOverTime(0.3);
    self.menu.options.alpha = 0;
    self.menu.background FadeOverTime(0.3);
    self.menu.background.alpha = 0;
    self.menu.title FadeOverTime(0.3);
    self.menu.title.alpha = 0;
    self.menu.scroller FadeOverTime(0.3);
    self.menu.scroller.alpha = 0;
    
    self.menu.open = false;
}

destroyMenu(player){
    player.MenuInit = false;
    closeMenu();
    wait 0.3;
    player.menu.options destroy();
    player.menu.background destroy();
    player.menu.scroller destroy();
    player.menu.title destroy();
    player notify("destroyMenu");
}

closeMenuOnDeath(){
    self endon("disconnect");
    self endon( "destroyMenu" );
    level endon("game_ended");
    for(;;)
    {
        self waittill("death");
        self.menu.closeondeath = true;
        self submenu("Main Menu", "Andrews Utility");
        closeMenu();
        self.menu.closeondeath = false;
        self.menu.title destroy();
    }
}

StoreShaders() {
    self.menu.background = self drawShader("white", 10, -5, 200, 300, (0, 0, 0), 0, 0);
    self.menu.scroller = self drawShader("white", 10, -500, 200, 17, (0, 0, 0), 255, 1);
}

StoreText(menu, title){
    self.menu.currentmenu = menu;
    self.menu.title destroy();
    string = "";
    self.menu.title = drawText(title, "objective", 2, 0, 300, (1, 1, 1), 0, 1, 5);
    self.menu.title FadeOverTime(0.3);
    self.menu.title.alpha = 1;
    
    for(i = 0; i < self.menu.menuopt[menu].size; i++)
    { string += self.menu.menuopt[menu][i]+ "\n"; }
    self.menu.options destroy();
    self.menu.options = drawText(string, "objective", 1.7, 300, 48, (1, 1, 1), 0, (0, 0, 0), 0, 4);
    self.menu.options FadeOverTime(0.3);
    self.menu.options.alpha = 1;
}

getPlayerName(player){
    playerName = getSubStr(player.name, 0, player.name.size);
    for(i=0; i < playerName.size; i++)
    {
        if(playerName[i] == "]")
            break;
    }
    if(playerName.size != i)
        playerName = getSubStr(playerName, i + 1, playerName.size);
    return playerName;
}

drawText(text, font, fontScale, x, y, color, alpha, glowColor, glowAlpha, sort){
    hud = self createFontString(font, fontScale);
    hud setText(text);
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowColor = glowColor;
    hud.glowAlpha = glowAlpha;
    hud.sort = sort;
    hud.alpha = alpha;
    return hud;
}

createFontString(font, fontScale){
    hud = newClientHudElem(self);
    hud.elemType = "font";
    hud.font = font;
    hud.fontScale = fontScale;
    hud.x = 0;
    hud.y = 0;
    hud.alignX = "left";
    hud.alignY = "top";
    hud.horzAlign = "left";
    hud.vertAlign = "top";
    return hud;
}

createText(font, fontScale, alignX, alignY, x, y, text){
    hud = newClientHudElem(self);
    hud.elemType = "text";
    hud.font = font;
    hud.fontScale = fontScale;
    hud.alignX = alignX;
    hud.alignY = alignY;
    hud.x = x;
    hud.y = y;
    hud.alpha = 1;
    hud setText(text);
    return hud;
}

drawShader(shader, x, y, width, height, color, alpha, sort){
    hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader(shader, width, height);
    hud.x = x;
    hud.y = y;
    return hud;
}

verificationToNum(status){
    if (status == "Host")
        return 2;
    if (status == "User")
        return 1;
    else
        return 0;
}

Iif(bool, rTrue, rFalse){
    if(bool)
        return rTrue;
    else
        return rFalse;
}

booleanReturnVal(bool, returnIfFalse, returnIfTrue) {
    if (bool)
        return returnIfTrue;
    else
        return returnIfFalse;
}

booleanOpposite(bool){
    if(!isDefined(bool))
        return true;
    if (bool)
        return false;
    else
        return true;
}

bankDeposit(){
    if(self.score >= 1000)
    {
        self.account_value += 1;
        self.score -= 1000;
        self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", self.account_value, level.banking_map);
        self iPrintLnBold("Deposited ^2$1,000 ^7| Balance: ^2$" + (self.account_value * 1000));
    }
    else
        self iPrintLnBold("Need ^1$1,000 ^7to deposit!");
}

bankWithdraw(){
    if(self.account_value >= 1)
    {
        self.account_value -= 1;
        self.score += 1000;
        self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", self.account_value, level.banking_map);
        self iPrintLnBold("Withdrew ^2$1,000 ^7| Balance: ^2$" + (self.account_value * 1000));
    }
    else
        self iPrintLnBold("^1Insufficient ^7funds!");
}

checkBalance(){
    if(!isDefined(self.account_value))
        self.account_value = self get_player_bank_account();
        
    if(isDefined(self.balanceHud))
        self.balanceHud destroy();
        
    self.balanceHud = self createText("objective", 1.2, "LEFT", "TOP", 10, 50, "Bank Balance: $" + (self.account_value * 1000));
}

toggle_zombie_counter(){
    if(!isDefined(self.zombieCounterActive))
        self.zombieCounterActive = false;
        
    self.zombieCounterActive = !self.zombieCounterActive;
    
    if(self.zombieCounterActive)
    {
        self thread zombie_counter();
        self iPrintLn("Zombie Counter: ^2ON");
    }
    else
    {
        self notify("stop_zombie_counter");
        if(isDefined(self.zombiecounter))
            self.zombiecounter destroy();
        self iPrintLn("Zombie Counter: ^1OFF");
    }
}

zombie_counter(){
    self endon("disconnect");
    self endon("stop_zombie_counter");
    level endon("game_ended");
    
    if(isDefined(self.zombiecounter))
        self.zombiecounter destroy();
    
    self.zombiecounter = self createText("objective", 1.2, "LEFT", "TOP", 10, 30, "Zombies: 0");
    
    while(self.zombieCounterActive)
    {
        count = level.zombie_total + get_current_zombie_count();
        self.zombiecounter setText("Zombies: " + count);
        wait 0.5;
    }
}

toggleAfk(){
    if(!isDefined(self.isAfk))
        self.isAfk = false;
    if(!self.isAfk)
    {
        self.isAfk = true;
        self iprintlnbold("AFK mode enabled");
        self enableInvulnerability();
        self allowSpectateTeam("allies", true);
        self allowSpectateTeam("axis", true);
        self setMoveSpeedScale(0);
        self disableWeapons();
        self hide();
    }
    else
    {
        self.isAfk = false;
        self iprintlnbold("AFK mode disabled. Godmode active for 45 seconds.");
        self thread safelyDisableAfk();
    }
}

safelyDisableAfk(){
    self allowSpectateTeam("allies", false);
    self allowSpectateTeam("axis", false);
    self setMoveSpeedScale(1);
    self enableWeapons();
    self show();
    wait 45;
    self disableInvulnerability();
}

toggle_fov(){
    if(!isDefined(self.currentFov))
        self.currentFov = 1;
    
    self.currentFov += 0.1;
    if(self.currentFov > 1.5)
        self.currentFov = 1;
        
    setDvar("cg_fovScale", self.currentFov);
    self iPrintLn("FOV Scale set to: ^2" + self.currentFov);
}

moneyMultiplier(){
    self endon("death");
    self endon("disconnect");
    multiplier = 1.03;
    while(true)
    {
        oldScore = self.score;
        wait 0.05;
        newScore = self.score;
        
        if(newScore > oldScore)
        {
            pointsEarned = newScore - oldScore;
            bonusPoints = int(pointsEarned * (multiplier - 1));
            
            if(bonusPoints > 0)
            {
                self.score += bonusPoints;
            }
        }
    }
}

set_increased_health(){
    self.maxhealth = 200;
    self.health = self.maxhealth;
}

get_player_bank_account(){
    if(!isDefined(self.account_value))
    {
        self.account_value = self maps\mp\zombies\_zm_stats::get_map_stat("depositBox", level.banking_map);
    }
    return self.account_value;
}

init_player_hud(){
    self endon("disconnect");
    
    self.healthHud = self createText("objective", 1.2, "LEFT", "TOP", 10, 10, "Health: 100");
    
    for(;;)
    {
        self.healthHud setText("Health: " + self.health);
        wait 0.1;
    }
}

auto_deposit_on_end_game(){
    level waittill("end_game");
    foreach(player in level.players)
    {
        if(isDefined(player.account_value))
        {
            player maps\mp\zombies\_zm_stats::set_map_stat("depositBox", player.account_value, level.banking_map);
        }
    }
}

get_current_zombie_count(){
    zombies = getaiarray("axis");
    return zombies.size;
}

toggleZombieESP(){
    self endon("disconnect");
    
    if(!isDefined(self.zombieESP))
        self.zombieESP = false;
    
    if(!self.zombieESP)
    {
        self thread enableZombieESP();
        self iPrintLn("Zombie ESP: ^2ON");
        self.zombieESP = true;
    }
    else
    {
        self thread disableZombieESP();
        self iPrintLn("Zombie ESP: ^1OFF");
        self.zombieESP = false;
    }
}

enableZombieESP(){
    self thread getZombieTargets();
}

disableZombieESP(){
    self notify("esp_end");
    if(isDefined(self.esp) && isDefined(self.esp.targets))
    {
        for(i = 0; i < self.esp.targets.size; i++)
        {
            if(isDefined(self.esp.targets[i].bottomline))
                self.esp.targets[i].bottomline destroy();
        }
    }
}

getZombieTargets(){
    self endon("disconnect");
    self endon("esp_end");
    level endon("game_ended");
    
    for(;;)
    {
        // Clean up old targets first
        if(isDefined(self.esp) && isDefined(self.esp.targets))
        {
            for(i = 0; i < self.esp.targets.size; i++)
            {
                if(isDefined(self.esp.targets[i].bottomline))
                    self.esp.targets[i].bottomline destroy();
            }
        }
        
        self.esp = spawnStruct();
        self.esp.targets = [];
        
        zombies = getaiarray("axis");
        
        for(i = 0; i < zombies.size; i++)
        {
            if(isDefined(zombies[i]) && isAlive(zombies[i]))
            {
                self.esp.targets[i] = spawnStruct();
                self.esp.targets[i].zombie = zombies[i];
                self thread monitorZombieTarget(self.esp.targets[i]);
            }
        }
        
        wait 2.0;
    }
}

monitorZombieTarget(target){
    self endon("disconnect");
    self endon("esp_end");
    self endon("UpdateZombieESP");
    level endon("game_ended");
    
    target.bottomline = self createZombieBottomLine();
    
    while(isDefined(target.zombie) && isAlive(target.zombie))
    {
        zombie_pos = target.zombie.origin;
        zombie_head = target.zombie getTagOrigin("j_head");
        
        // Position bottom line
        target.bottomline.x = zombie_pos[0];
        target.bottomline.y = zombie_pos[1];
        target.bottomline.z = zombie_pos[2] + 35;
        
        // Check visibility and set colors
        outline_color = (1, 0, 0); // Red for visible
        if(!bulletTracePassed(self getTagOrigin("j_head"), zombie_head, false, self))
        {
            outline_color = (0, 1, 0); // Green for not visible
        }
        
        target.bottomline.color = outline_color;
        
        wait 0.05;
    }
    
    // Cleanup
    if(isDefined(target.bottomline))
        target.bottomline destroy();
}
createZombieBottomLine(){
    bottomline = newClientHudElem(self);
    bottomline.elemtype = "icon";
    bottomline.sort = 1;
    bottomline.archived = false;
    bottomline.alpha = 0.8;
    bottomline.color = (1, 0, 0);
    bottomline setShader("white", 20, 1); // Horizontal line
    bottomline setWaypoint(true, true);
    return bottomline;
}





