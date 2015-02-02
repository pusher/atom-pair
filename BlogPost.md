#Introducing AtomPair, The Ultimate Pair Programming Experience for Atom.IO

We are starting to really love [Atom](http://atom.io) at Pusher. Its customizability is hugely beneficial to our workflow, and its API is awesome and very well documented indeed. There is a big community building around it, and the product seems to get better with every release. 

However, there was always one thing we wanted to do with it...

You see, we're fairly big on pair programming, but many of us work remotely. Of course, there are many existing solutions to this: screen sharing, browser pairing, or not pairing at all.

But none of those quite suited our needs. We wanted something immediate, almost frictionless, something that dissolves the distance between collaborators. Atom, built on hackability, seemed like the perfect medium: to pair together *within* a text editor sounded ideal. We had tried [Firebase's Atom FirePad](https://github.com/firebase/atom-firepad), which is very cool and super easy to use, but was perhaps lacking in some areas that we needed for our daily work. 

Therefore, we decided to build **AtomPair**, and now we want to share the ♥.

##How Do I Get Started?

###Install

First off, install Atom if you haven't already. Now type into your terminal:

    $ apm install atom-pair
    
Alternatively, go to the command palette via `command+shift+p` and go to `Install Packages and Themes`. Then search for and install AtomPair.

###Invite

You can either decide to pair on a blank slate, or on existing code. If you invite somebody to collaborate on existing code, they will see everything you can, and their syntax highlighting will be synchronized with yours.

As detailed below, there are two ways you can invite others. Given a free Sandbox plan, there will be a maximum of 20 collaborators per session.

####Basic

Hit `command+shift+p`, and in the command palette, hit `AtomPair: Start A New Pairing Session`. 

You will be given a session ID, hit `command+c` and paste that to a friend.

####HipChat

The other way, one that we use quite often, is to invite collaborators over HipChat. We wanted this partly as an easy way of giving collaborators a session ID, but also so that other members of the team could join in if they wanted to. 

If you have admin privileges in a HipChat organization, type `command+shift+p` and go to `AtomPair: Set configuration keys`. Enter your HipChat API key and the room you wish the invitation to be sent through. 

Now, when you enter `AtomPair: Invite Over HipChat` and enter your collaborator's HipChat @mention_name in the command palette, they will receive an invitation with a session ID.

![HipChat Invite](https://raw.githubusercontent.com/pusher/atom-pair/blog_post/images/hipchat.jpg)

###Collaborate!

![Demo](https://raw.githubusercontent.com/pusher/atom-pair/blog_post/images/demo.gif)

Once your partner has a session ID, they should go to the command pallette and hit `AtomPair: Join a pairing session`, and enter the ID. 

Once there are more than one of you in a session, your collaborators will be represented by a coloured marker in the gutter, which will changed position based on their selections and inputs. 

To end a pairing session, go to `AtomPair: Disconnect`, and you will be disconnected from Pusher, and the file will be free for you to save.

##Free And Open For Everyone

Currently, you are given default Pusher credentials when you install the package, so that you can get started with as less friction as possible. Communication will take place over a randomly generated channel name. However, for improved security, we encourage you to [create a free account]() and enter your own app key and app secret by going to `AtomPair: Set configuration keys` in the command palette. A free Sandbox plan should be more than enough for your pairing sessions.

###Contributing

Here is a current list of features:

* Text synchronization
* File-sharing
* HipChat invitations
* Synchronized syntax highlighting
* Collaborator visibility.

But if there are any features you find lacking, feel more than welcome to [get in contact with the maintainer](jamie@pusher.com).

Happy pairing!

 



