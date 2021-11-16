import pygame
from pygame import mixer

import math
import random

# Intialize the pygame
pygame.init()

# Create the Screen Dimensions (Width, Height)
screen = pygame.display.set_mode((800,600))

# Background (background.png image size: 800 x 600)
background = pygame.image.load('background.png')

# Background Sound
mixer.music.load('background.wav')
mixer.music.play(-1)

# The Games Border Caption and Images (ufo.png image size: 32 x 32)
pygame.display.set_caption("Space Invaders")
icon = pygame.image.load('ufo.png')
pygame.display.set_icon(icon)

# Player (player.png image size: 64 x 64)(playerX position: 370)(playerY position: 480)
playerImg = pygame.image.load('player.png')
playerX = 370
playerY = 480
playerX_change = 0

# Enemy (enemy.png image size: 64 x 64)(Multiple enemies are generated through lists[])
enemyImg = []
enemyX = []
enemyY = []
enemyX_change = []
enemyY_change = []
num_of_enemies = 8 # This is how many enemies appear on the screen


for i in range(num_of_enemies):
    enemyImg.append(pygame.image.load('enemy.png'))
    enemyX.append(random.randint(0, 800))
    enemyY.append(random.randint(50, 150))
    enemyX_change.append(0.4)
    enemyY_change.append(40)


# Bullet (Ready - You can't see the bullet on the screen)(Fire - The bullet is currently moving)
bulletImg = pygame.image.load('bullet.png')
bulletX = 0
bulletY = 480
bulletX_change = 0
bulletY_change = 10
bullet_state = "ready"

# Score and Font
score_value = 0
font = pygame.font.Font('freesansbold.ttf', 32) # This is how you change the font and text size
textX = 10
testY = 10

# Game Over Text
over_font = pygame.font.Font('freesansbold.ttf', 64)

# Defining the functions that will be used for the characters and animations
def show_score(x, y): # This is defining what will be value displayed to the user when they shoot an enemy
    score = font.render("Score : " + str(score_value), True, (0, 255, 0)) # This is where you can edit the characters displayed on screen represnting the Score or Hits
    screen.blit(score, (x, y))

def game_over_text():
    over_text = over_font.render("GAME OVER", True, (255, 0, 0))
    screen.blit(over_text, (200, 250))

def player(x, y):
    screen.blit(playerImg, (x, y))

def enemy(x, y, i):
    screen.blit(enemyImg[i], (x, y))

def fire_bullet(x, y):
    global bullet_state
    bullet_state = "fire"
    screen.blit(bulletImg, (x + 16, y + 10)) # This is where the bullet is fired from on the player spaceship (centered)

def isCollision(enemyX, enemyY, bulletX, bulletY): # This is how a collision is detected (mathematical calculation below)
    distance = math.sqrt((math.pow(enemyX - bulletX, 2)) + math.pow(enemyY - bulletY,2))
    if distance < 27:
        return True
    else:
        return False


# Game Loop
running = True
while running:
    
    # RGB (Red, Green, Blue)(The command: screen.fill((0, 0, 0)) needs to be above everything in the Game Loop since that is what is getting drawn on first) 
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    
        # If a Key is pressed check whether its LEFT or RIGHT and than move 0.5 spaces over in that direction 
        # If the SPACE bar is pressed than fire a bullet from the x coordinate of the player spaceship
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_LEFT:
                playerX_change = -0.5
            if event.key == pygame.K_RIGHT:
                playerX_change = 0.5
            if event.key == pygame.K_SPACE:
                if bullet_state is "ready":
                    bullet_Sound = mixer.Sound('laser.wav')
                    bullet_Sound.play()
                    bulletX = playerX # Get the current x coordinate of the spaceship
                    fire_bullet(bulletX, bulletY)
        # If the a Key is released than stop             
        if event.type == pygame.KEYUP:
            if event.key == pygame.K_LEFT or event.key == pygame.K_RIGHT:
                playerX_change = 0
    

    # Checks for the boundaries set so that the spaceship doesn't go out of bounds
    playerX += playerX_change
    
    if playerX <= 0:
        playerX = 0
    elif playerX >= 736:
        playerX = 736
    
    # Enemy Movement
    for i in range(num_of_enemies):

    # Game Over
        if enemyY[i] > 440: # This is where the enemy will be destroyed if they reaches 440
            for j in range(num_of_enemies):
                enemyY[j] = 2000
            game_over_text()
            break

    
        enemyX[i] += enemyX_change[i]
        if enemyX[i] <= 0:
            enemyX_change[i] = 0.4
            enemyY[i] += enemyY_change[i]
        elif enemyX[i] >= 736:
            enemyX_change[i] = -0.4
            enemyY[i] += enemyY_change[i]

        # Collision (Determines what is considered a collision)
        collison = isCollision(enemyX[i], enemyY[i], bulletX, bulletY)
        if collison: 
            explosion_Sound = mixer.Sound('explosion.wav')
            explosion_Sound.play()
            bulletY = 480
            bullet_state = "ready"
            score_value += 1
            enemyX[i] = random.randint(0, 736)
            enemyY[i] = random.randint(50, 150)

        enemy(enemyX[i], enemyY[i], i)

    # Bullet Movement
    if bulletY <=0:
        bulletY = 480
        bullet_state = "ready"

    if bullet_state is "fire": 
        fire_bullet(bulletX, bulletY)
        bulletY -= bulletY_change


    player(playerX, playerY)
    show_score(textX, testY)
    pygame.display.update() 
# The command: pygame.display.update() is constantly refreshing the image so that the player can see images and movement on the screen
