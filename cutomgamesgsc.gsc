#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;

init()
{
    level thread onPlayerConnect();
    level thread auto_deposit_on_end_game();
    
    // Ensure the script runs in both server and custom games
    setDvar("sv_allowscript", 1);
    setDvar("sv_cheats", 1);
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
        player thread init_rank_data();
        player.account_value = player get_player_bank_account();
        player check_bank_balance();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    
    for(;;)
    {
        self waittill("spawned_player");
        self thread modMenu();
        self thread init_player_hud();
        self thread set_increased_health();
        self thread moneyMultiplier();
        self thread create_menu_instructions();
        self.zombieCounterActive = false;
    }
}

create_menu_instructions()
{
    self endon("disconnect");
    
    instructions = self createText("objective", 1.0, "RIGHT", "TOP", -10, 10, "^3ADS + Melee^7: Open Menu | ^3Crouch^7: Close Menu");
    instructions.alpha = 0.8;
    instructions.hideWhenInMenu = true;
}

modMenu()
{
    self endon("disconnect");
    
    menuTitle = "^2Control ^4Panel";
    menuItems = [];
    menuItems[0] = "Rankup ($40,000)";
    menuItems[1] = "Rank Status";
    menuItems[2] = "Withdraw 25%";
    menuItems[3] = "Withdraw 50%";
    menuItems[4] = "Withdraw 100%";
    menuItems[5] = "Deposit 25%";
    menuItems[6] = "Deposit 50%";
    menuItems[7] = "Deposit 100%";
    menuItems[8] = "Check Balance";
    menuItems[9] = "Toggle Zombie Counter";
    menuItems[10] = "Toggle AFK Mode";
    
    menuElements = self createMenu(menuTitle, menuItems);
    
    currentItem = 0;
    menuOpen = false;
    lastInputTime = 0;
    
    self toggleMenuVisibility(false, menuElements);
    
    while(1)
    {
        if(self AdsButtonPressed() && self MeleeButtonPressed() && getTime() > lastInputTime + 500)
        {
            menuOpen = !menuOpen;
            self toggleMenuVisibility(menuOpen, menuElements);
            lastInputTime = getTime();
        }
        
        if(menuOpen)
        {
            currentItem = self handleMenuInput(menuElements, currentItem, menuItems.size, (0.5, 0, 0.5));
            
            if(self jumpButtonPressed() && getTime() > lastInputTime + 200)
            {
                switch(currentItem)
                {
                    case 0:
                        self thread rankup_logic();
                        break;
                    case 1:
                        self thread status_logic();
                        break;
                    case 2:
                        self thread withdraw_logic(0.25);
                        break;
                    case 3:
                        self thread withdraw_logic(0.5);
                        break;
                    case 4:
                        self thread withdraw_logic(1);
                        break;
                    case 5:
                        self thread deposit_logic(0.25);
                        break;
                    case 6:
                        self thread deposit_logic(0.5);
                        break;
                    case 7:
                        self thread deposit_logic(1);
                        break;
                    case 8:
                        self thread balance_logic();
                        break;
                    case 9:
                        self thread toggle_zombie_counter();
                        break;
                    case 10:
                        self thread toggleAfk(self);
                        break;
                }
                lastInputTime = getTime();
            }
            else if(self stanceButtonPressed() && getTime() > lastInputTime + 200)
            {
                menuOpen = false;
                self toggleMenuVisibility(false, menuElements);
                lastInputTime = getTime();
            }
        }
        
        wait 0.05;
    }
}

createMenu(title, items)
{
    menuElements = [];
    
    menuElements["background"] = self createRectangle("LEFT", "CENTER", 20, 100, 180, 270, (0, 0, 0), 0.7);
    menuElements["background"] setShader("white", 180, 270);
    menuElements["background"].sort = -1;

    menuElements["title"] = self createText("objective", 1.4, "LEFT", "TOP", 122, 77, title);
    
    menuElements["options"] = [];
    
    startY = 100;
    spacing = 20;
    for(i = 0; i < items.size; i++)
    {
        menuElements["options"][i] = self createText("objective", 1.1, "LEFT", "TOP", 75, startY + (i * spacing), items[i]);
    }
    
    menuElements["instructions"] = self createText("objective", 0.9, "LEFT", "BOTTOM", 25, 365, "^3Jump^7: Select | ^3Crouch^7: Back");
    
    return menuElements;
}

toggleMenuVisibility(visible, menuElements)
{
    menuElements["background"].alpha = visible ? 0.7 : 0;
    menuElements["title"].alpha = visible ? 1 : 0;
    menuElements["instructions"].alpha = visible ? 1 : 0;
    
    foreach(option in menuElements["options"])
    {
        option.alpha = visible ? 1 : 0;
    }
}

handleMenuInput(menuElements, currentItem, itemCount, highlightColor)
{
    if(self actionSlotOneButtonPressed() && getTime() > self.lastInputTime + 200)
    {
        menuElements["options"][currentItem].color = (1, 1, 1);
        currentItem = (currentItem - 1 + itemCount) % itemCount;
        menuElements["options"][currentItem].color = highlightColor;
        self.lastInputTime = getTime();
    }
    else if(self actionSlotTwoButtonPressed() && getTime() > self.lastInputTime + 200)
    {
        menuElements["options"][currentItem].color = (1, 1, 1);
        currentItem = (currentItem + 1) % itemCount;
        menuElements["options"][currentItem].color = highlightColor;
        self.lastInputTime = getTime();
    }
    
    return currentItem;
}

createRectangle(alignX, alignY, x, y, width, height, color, alpha)
{
    rect = newClientHudElem(self);
    rect.alignX = alignX;
    rect.alignY = alignY;
    rect.x = x;
    rect.y = y;
    rect.width = width;
    rect.height = height;
    rect.color = color;
    rect.alpha = alpha;
    rect.shader = "white";
    rect.sort = 0;
    rect.borderwidth = 2;
    rect.bordercolor = (0.5, 0.5, 0.5);
    return rect;
}

createText(font, fontScale, alignX, alignY, x, y, text)
{
    hudText = newClientHudElem(self);
    hudText.fontScale = fontScale;
    hudText.x = x;
    hudText.y = y;
    hudText.alignX = alignX;
    hudText.alignY = alignY;
    hudText.horzAlign = alignX;
    hudText.vertAlign = alignY;
    hudText.font = font;
    hudText setText(text);
    return hudText;
}

init_player_hud()
{
    self endon("disconnect");
    
    self.healthHud = self createText("objective", 1.2, "LEFT", "TOP", 10, 10, "Health: 100");
    
    for(;;)
    {
        self.healthHud setText("Health: " + self.health);
        wait 0.1;
    }
}

set_increased_health()
{
    self.maxhealth = 200;
    self.health = self.maxhealth;
}

auto_deposit_on_end_game()
{
    level waittill("end_game");
    wait 1;
    foreach(player in level.players)
        player deposit_logic(1);
}

get_player_bank_account()
{
    if(!isDefined(self.bank_account))
    {
        self.bank_account = 10000; // Default starting amount
    }
    return self.bank_account;
}

check_bank_balance()
{
    value = self.bank_account;
    self iprintln("^7Checking bank balance...");
    wait 1.5;
    self iprintln("^7You have ^1" + self convert_to_money(value) + "^7 in the bank!");
}

convert_to_money(rawvalue)
{
    return "$^2" + convert_to_thousands(rawvalue);
}

convert_to_thousands(rawvalue)
{
    rawstring = "" + rawvalue;
    leftovers = rawstring.size % 3;
    commasneeded = (rawstring.size - leftovers) / 3;
    if(leftovers == 0)
    {
        leftovers = 3;
        commasneeded = commasneeded - 1;
    }
    if(commasneeded < 1)
    {
        return rawvalue;
    }
    else if(commasneeded == 1)
    {
        return getSubStr(rawvalue, 0, leftovers) + "," + getSubStr(rawvalue, leftovers, leftovers+3);
    }
    else if(commasneeded == 2)
    {
        return getSubStr(rawvalue, 0, leftovers) + "," + getSubStr(rawvalue, leftovers, leftovers+3) + "," + getSubStr(rawvalue, leftovers+3, leftovers+6);
    }
    else if(commasneeded == 3)
    {
        return getSubStr(rawvalue, 0, leftovers) + "," + getSubStr(rawvalue, leftovers, leftovers+3) + "," + getSubStr(rawvalue, leftovers+3, leftovers+6) + "," + getSubStr(rawvalue, leftovers+6, leftovers+9);
    }
}

deposit_logic(percentage)
{
    num_score = int(self.score);
    num_amount = int(num_score * percentage);

    if(num_amount <= 0)
    {
        self iPrintLn("^7Deposit failed: Not enough money");
        return;
    }

    self bank_add(num_amount);
    self.score -= num_amount;
    self iPrintLn("^7Successfully deposited ^1" + convert_to_money(num_amount));
}

withdraw_logic(percentage)
{
    balance = self bank_read();
    num_amount = int(balance * percentage);

    if(balance <= 0)
    {
        self iPrintln("^7Withdraw failed: you have no money in the bank");
        return;
    }
    if(self.score >= 1000000)
    {
        self iPrintLn("^7Withdraw failed: Max score is ^1$^21,000,000.");
        return;
    }

    if(num_amount > balance)
        num_amount = balance;
    
    over_balance = self.score + num_amount - 1000000;
    max_score_available = abs(self.score - 1000000);
    if(over_balance > 0)
        num_amount = max_score_available;
    
    self bank_sub(num_amount);
    self.score += num_amount;
    self iPrintLn("^7Successfully withdrew ^1" + convert_to_money(num_amount));
}

balance_logic()
{
    value = self bank_read();
    self iPrintLn("^7Current balance: ^1" + self convert_to_money(value));
}

bank_add(value)
{
    self.bank_account += value;
}

bank_sub(value)
{
    self.bank_account -= value;
}

bank_read()
{
    return self.bank_account;
}

bank_write(value)
{
    self.bank_account = value;
}

moneyMultiplier()
{
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

init_rank_data()
{
    if(!isDefined(self.rankLevel))
    {
        self.rankLevel = 1;
        self.rankBonus = 0;
    }
}

rankup_logic()
{
    POINTS_REQUIRED = 40000;
    MAX_BONUS = 0.25; // 25%

    if (self.score >= POINTS_REQUIRED)
    {
        self.score -= POINTS_REQUIRED;
        currentBonus = self.rankBonus;
        newBonus = currentBonus + 0.05;
        if (newBonus > MAX_BONUS)
        {
            newBonus = MAX_BONUS;
        }
        self.rankBonus = newBonus;
        self.rankLevel += 1;
        self iPrintLnBold("^7Rank-up successful! Level: " + self.rankLevel);
        self iPrintLnBold("^7Point Scaling: " + (self.rankBonus * 100) + "%");
        self iPrintLnBold("^7Bullet Damage: " + (self.rankBonus * 100) + "%");
    }
    else
    {
        self iPrintLnBold("^7Not enough points to rank up. You need " + (POINTS_REQUIRED - self.score) + " more points.");
    }
}

status_logic()
{
    self iPrintLn("^7Current Level: ^1" + self.rankLevel);
    wait 0.5;
    self iPrintLn("^7Point Scaling: ^1" + int(self.rankBonus * 100) + "%");
    wait 0.5;
    self iPrintLn("^7Bullet Damage Bonus: ^1" + int(self.rankBonus * 100) + "%");
}

toggle_zombie_counter()
{
    self.zombieCounterActive = !self.zombieCounterActive;
    if(self.zombieCounterActive)
    {
        self thread zombie_counter();
        self iPrintLn("Zombie Counter: ^2ON");
    }
    else
    {
        if(isDefined(self.zombiecounter))
        {
            self.zombiecounter destroy();
        }
        self iPrintLn("Zombie Counter: ^1OFF");
    }
}

zombie_counter()
{
    self endon("disconnect");
    level endon("game_ended");
    
    if(isDefined(self.zombiecounter))
    {
        self.zombiecounter destroy();
    }
    
    flag_wait("initial_blackscreen_passed");
    self.zombiecounter = createfontstring("Objective", 1.7);
    self.zombiecounter setpoint("CENTER", "CENTER", -200, 200);
    self.zombiecounter.alpha = 1;
    self.zombiecounter.hidewheninmenu = 1;
    self.zombiecounter.hidewhendead = 1;
    self.zombiecounter.label = &"Zombies Left: ^1";
    
    while(self.zombieCounterActive)
    {
        if(isDefined(self.afterlife) && self.afterlife)
        {
            self.zombiecounter.alpha = 0.2;
        }
        else
        {
            self.zombiecounter.alpha = 1;
        }
        self.zombiecounter setvalue(level.zombie_total + get_current_zombie_count());
        wait 0.05;
    }
    
    self.zombiecounter destroy();
}

toggleAfk(player)
{
    if(!isDefined(player.isAfk))
        player.isAfk = false;

    if(!player.isAfk)
    {
        player.isAfk = true;
        player iprintlnbold("AFK mode enabled");
        player enableInvulnerability();
        player allowSpectateTeam("allies", true);
        player allowSpectateTeam("axis", true);
        player setMoveSpeedScale(0);
        player disableWeapons();
        player hide();
        
        // Hide HUD elements
        if(isDefined(player.balanceHud))
            player.balanceHud.alpha = 0;
        if(isDefined(player.healthHud))
            player.healthHud.alpha = 0;
        if(isDefined(player.zombiecounter))
            player.zombiecounter.alpha = 0;
    }
    else
    {
        player.isAfk = false;
        player iprintlnbold("AFK mode disabled. Godmode active for 45 seconds.");
        player thread safelyDisableAfk();
        
        // Show HUD elements
        if(isDefined(player.balanceHud))
            player.balanceHud.alpha = 0.8;
        if(isDefined(player.healthHud))
            player.healthHud.alpha = 1;
        if(isDefined(player.zombiecounter))
            player.zombiecounter.alpha = 1;
    }
}

safelyDisableAfk()
{
    self endon("disconnect");

    self allowSpectateTeam("allies", false);
    self allowSpectateTeam("axis", false);
    self setMoveSpeedScale(1);
    self enableWeapons();
    self show();

    // Keep godmode for 45 seconds
    wait 45;

    if(!self.isAfk) // Check if player hasn't re-enabled AFK
    {
        self disableInvulnerability();
        self iprintlnbold("Godmode deactivated. Be careful!");
    }
}

// Utility function to get current zombie count
get_current_zombie_count()
{
    return getAIArray().size;
}