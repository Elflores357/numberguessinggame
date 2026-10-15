#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

printf 'Enter your username: '
IFS= read -r username
escaped_username=${username//\'/\'\'}
user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$escaped_username';")

if [[ -z $user_id ]]; then
  $PSQL "INSERT INTO users(username) VALUES('$escaped_username');" > /dev/null
  user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$escaped_username';")
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
else
  IFS='|' read -r games_played best_game <<< "$($PSQL "SELECT COUNT(*), COALESCE(MIN(number_of_guesses), 0) FROM games WHERE user_id = $user_id;")"
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$username" "$games_played" "$best_game"
fi

secret_number=$((RANDOM % 1000 + 1))
number_of_guesses=0
printf 'Guess the secret number between 1 and 1000:\n'

while IFS= read -r guess; do
  ((number_of_guesses += 1))

  if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
    printf 'That is not an integer, guess again: '
  else
    if [[ $guess == -* ]]; then
      guess_value=$((-10#${guess#-}))
    elif [[ $guess == +* ]]; then
      guess_value=$((10#${guess#+}))
    else
      guess_value=$((10#$guess))
    fi

    if (( guess_value > secret_number )); then
      printf "It's lower than that, guess again: "
    elif (( guess_value < secret_number )); then
      printf "It's higher than that, guess again: "
    else
      printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$number_of_guesses" "$secret_number"
      $PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($user_id, $number_of_guesses);" > /dev/null
      exit 0
    fi
  fi
done
