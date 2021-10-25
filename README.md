# Escape Hash

Escape Hash is a (relatively simple) programming challenge that can be used to illustrate, or learn about, multiple concepts.

You can use it as a sandbox to learn about the following things:
- difference of speed between shell scripts and Python scripts;
- executing code directly vs. putting it behind an API gateway vs. executing it via a work queue;
- space/time complexity trade-offs;
- scaling code for performance;
- latency and prioritization.

## Gettting psyched

*The evil Doctor Hash has locked you and your team in the basement of their evil lair. The basement door is locked with a code. The only way to exit the basement and escape the lair is to crack the code!*

*There is just one slight little problem: the door code is a 15-digit number. That's way too many possibilities to try them all manually! Fortunately, you have some extra information about the door code. Here is the message the was left by one of your spies.*

> *“Alright, I don't have the door code quite yet, and when I have it, I will leave it in the basement. Except if I just write down the door code, the evil cleaning robots will find it and destroy it; so I need to make it look like something else. Here is what I will do: I will split the door code into 5 chunks of 3 digits each. Then I will compute a salted hash of each chunk, and leave these hashes in plain sight. The cleaning robots will think that it's some important research information and leave it here. The salt will be our team name, followed by a dot, and we will also add a carriage return after the number when computing the hash.”*

*Since these instructions were a bit confusing, we asked the agent to send us an example.*

> *“Imagine that the door code is 123456789444222, then the chunks will be 123 456 789 444 222. If our team name is `"rainbow"`, I will compute the SHA256 hash of `"rainbow.123\n"`, then of `"rainbow.456\n"`, and so on. I'm going to send you a little shell snippet to show exactly what I mean.”*

*And here is the shell snippet:*

```bash
for CHUNK in 123 456 789 444 222; do
  echo rainbow.$CHUNK | sha256sum
done
```

*And the five hashes corresponding to the five chunks would then be:*

```
a60674cb65abb648bd8767590ee38d5770105faa5151cce0e8d1c8673357ca2f
946b2be63d7e57cc16f3c99c63da87f724e0c9575bd7b8fcca3dc0c3c1d8d276
1c8f9f96a75ce641bc6a744c7bc75beeda2c0bc6e951a76fb2745750398f5cda
dd1bba54d476eebaa54e2baf03c3296cddadec18b92531606a52ccbc71a054f8
79c39c1edfd80397ba81fbf68d5204e56f7c1ad1b71cc5b68c9de1c0e5184aab
```

*Now you're in the basement. We'll tell you how to get these hashes, and all you'll have to do is find out the numbers behind them, and then you'll be able to escape the basement of the evil lair before Doctor Hash blows everything up! (Why do evil Doctors always want to blow everything up anyway?)*

## Getting started

Escape Hash is an API server. Through that API, you can ask "challenges" and submit "solutions" for validation.

The "challenges" are list of hashes.

The "solutions" are big numbers (long strings of digits).

When communicating with the API server, almost every API call specifies a "team". The "team" is used as a seed to generate the challenges, so that every team will have different challenges. (In the intro story, the team name was `rainbow`.)

Each challenge has a *difficulty* and a *count*.

The *difficulty* indicates how many digits there are in each chunk of the challenge. (In the intro story, the difficulty was 3.)

Note: the chunks can't actually start with zeroes, so if difficulty=3, it means that each chunk is a number between 100 and 999 (both included).

The *count* indicates how many chunks there are in the challenge. (In the intro story, the count was 5.)

As a reminder, each hash is calculated by taking the SHA256 checksum (in hex digest form) of:

`team name` + `.` + `random number` + `\n`.


Example: let's say that a challenge has `difficulty=5` and `count=2`. The final code will be 5x2=10 digits. If the final code is `1234542420`, the chunks would be `12345` and `42420`. For team `purple`, the hashes would be shown by the commands below:

```bash
$ echo purple.12345 |sha256sum 
cdd4debbea46e08fc81832ebf41d1b1cffb0e6d37b22401947906a79895aac5f  -
$ echo purple.42420 | sha256sum 
0c38eb462addee5d0270e0990f96778715bf57a39a51fc157f76caba1f7766b4  -
```

So the steps are:

1. Obtain the list of hash from the API server.
2. Guess (probably by brute force) which numbers were used to generate each hash.
3. Concatenate all these numbers to reconstruct the original code.
4. Submit the code to the API server for validation.


## Example

First, start the server. By default it will listen on localhost, port 5000:

```bash
./escapehash.py
```

Retrieve the list of challenges:

```bash
curl -s localhost:5000/v1/challenges | jq .
```

We're going to focus on the first two challenges, `test1` and `test2`:

```json
[
  {
    "name": "test1",
    "difficulty": 1,
    "count": 1
  },
  {
    "name": "test2",
    "difficulty": 1,
    "count": 2
  },
  // ...
```

Let's pick a team name, e.g. `purple`. Then retrieve the hash list for challenge `test1`.

```bash
curl localhost:5000/v1/team/purple/challenge/test1.txt
```

It gives us one hash:

```
cea1bd1a83524ac50bfe3545b0ab6ec32aeea73ad24f87a7b41e81e24ef5ac54
```

Now we must find a number `N` from 1 to 9, such as `echo purple.N | sha256sum` corresponds to that hash.

```bash
for N in $(seq 1 9); do
  echo "$(sha256sum <<< purple.$N)  $N"
done
```

The output looks like this:
```
366c0f5bc681294aa7081c32cf8b777c5e52526b6fb879d555b746a204b8ea83  -  1
d3e463e88f89910ade5878a9c585314d6941e8009dfa915b53feba7eb7a5704d  -  2
b0757b064e6e74018301641d57165d73e5afea08d53ef7f765ab7ee9e15ebe27  -  3
665ee796c70587fe671706259bc7a336c7123e44a7fac183773fa250335e07b9  -  4
7f006e51eea322d77b3b561fe53811de8dbc7c27235897592d0b7995dae1b29b  -  5
bc7f5ae433791321911ddd98072142229ef49a729aacb9c35a2156176e92e651  -  6
49a55b6293e8467b16933a7b338c8614d630c40a6e2e1e3f3af5e2aec19b2feb  -  7
34051f4ad6ef41dfb6f51ab91d1a8469c1d51db86b0c86912610a7e7005417f9  -  8
cea1bd1a83524ac50bfe3545b0ab6ec32aeea73ad24f87a7b41e81e24ef5ac54  -  9
```

So the solution seems to be `9`.

We can check our solution:

```bash
curl localhost:5000/v1/team/purple/challenge/test1 \
     -H content-type:text/plain --data 9
```

And it should tell us:

```
Well done!
```

Now we can try the next challenge, `test2`:

```bash
curl localhost:5000/v1/team/purple/challenge/test2.txt
```

It has the same difficulty, `1`, but it has a count of `2`, so it lists two hashes:

```
b0757b064e6e74018301641d57165d73e5afea08d53ef7f765ab7ee9e15ebe27
cea1bd1a83524ac50bfe3545b0ab6ec32aeea73ad24f87a7b41e81e24ef5ac54
```

Using the list we got above, the first one corresponds to `3` and the second one is `9` again.

So we submit `39`:

```bash
curl localhost:5000/v1/team/purple/challenge/test1 \
     -H content-type:text/plain --data 9
```

And we get the `Well done!` message again.

Note: here we only have 9 possile so it's really easy to just list them and look them up; but in higher difficulties, there are way more possibilities, of course.

See `solver.sh` for a very naive implementation using purely shell commands.

## API specification

### List challenges

- Request: GET /v1/challenges
- Response: a JSON document listing the challenges

- Request: GET /v1/team/{teamname}/challenge/{challengename}.txt
- Response: The challenge hashes, one per line

- Request: GET /v1/team/{teamname}/challenge/{challengename}.json
- Response: The challenge hashes, as a JSON array

- Request: POST /v1/team/{teamname}/challenge/{challengename}
- Body: all numbers concatenated together
- Response: 200 OK or 406 Not Acceptable HTTP code
