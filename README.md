# github-cleanup

You've got a lot of repos.  Like, thousands.  Some of them probably aren't used any more, or never were.  How do you find the dead weight?

Github's API is not informative enough to help you, so these scripts will:
1) Retrieve the full list of repos in your Github organization.
2) Clone them all locally, and checkout whichever branch has the latest commit.
3) Assign a weight ("heat") to each repo for how likely it is to be useless, and aggregate those stats into a CSV file for ease of cajoling your coworkers.

You will need `jq`.


TODO:
- Document usage, add "do everything" script
- Support stdin/out, remove hardcoded files
- Pass "created_at" through the pipeline
- Move the "ignore recently-created repos" code into the bash side so you don't need an intermediate .json file.
- Create a whitelist facility
