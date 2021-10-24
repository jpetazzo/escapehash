# Escape Hash

Escape Hash is a little programming challenge to illustrate how to run jobs of various sizes, for instance:

- small jobs (a few seconds or less) that can be placed behind an API gateway
- bigger jobs (from a minute to a few hours) that can leverage a job scheduler (e.g. Kubernetes "Job" resources)

Escape Hash is an API server. Through that API, you can ask "challenges" (problems to solve) and submit challenge answers for validation.

In concrete terms, the challenges are hashes, and you must reverse the hash. This is CPU-intensive, and the amount of work to solve a challenge is easily adjustable.

When communicating with the API server, almost every API call specifies a "team". The "team" is used as a seed to generate the challenges, so that every team will have different challenges.

## Challenges and answers

Each challenge has a *difficulty* and a *count*.

The *count* indicates how many hashes there are in the challenge; and the *difficulty* indicates the size of the number used to generate the hash.

Each hash is the SHA256 checksum (in hex digest form) of:

`team name` + `random number` + `\n`.

Each random number has N digits, where N is the difficulty of the challenge, and it cannot start with zeros. So for instance, for difficulty 3, the random number can go from 100 to 999.

So in a challenge with `difficulty=5` and `count=2`, the random numbers could be `12345` and `42420`. For team `purple`, the hashes would be shown by the commands below:

```bash
$ echo purple.12345 |sha256sum 
cdd4debbea46e08fc81832ebf41d1b1cffb0e6d37b22401947906a79895aac5f  -
$ echo purple.42420 | sha256sum 
0c38eb462addee5d0270e0990f96778715bf57a39a51fc157f76caba1f7766b4  -
```

The answer that must be submitted to the API server is the concatenation of all the numbers. In the example above, that would be `1234542420`.


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
