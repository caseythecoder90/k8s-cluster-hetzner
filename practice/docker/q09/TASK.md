# q09 — clean up someone else's mess

A previous session left containers and an image behind.

1. Host port **18081** is taken by a container. Find out which one — from
   Docker, not by guessing — and remove it.
2. Another container has already exited. Remove that one too.
3. Remove the image `ckad-junk:v1`.
4. Start a fresh `nginx:1-alpine` container named **ckad-new**, detached, on
   host port 18081.

Do them in an order that works. (Step 3 will refuse until something else is
done first — that refusal is the lesson.)
