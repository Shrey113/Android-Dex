document.addEventListener('DOMContentLoaded',function(){
    const navbar=document.querySelector('.navbar');
    let lastScroll=0;
    window.addEventListener('scroll',function(){
        const currentScroll=window.pageYOffset;
        if(currentScroll>50){
            navbar.style.background='rgba(10,10,15,0.95)';
        }else{
            navbar.style.background='rgba(10,10,15,0.85)';
        }
        lastScroll=currentScroll;
    });

    document.querySelectorAll('a[href^="#"]').forEach(anchor=>{
        anchor.addEventListener('click',function(e){
            e.preventDefault();
            const target=document.querySelector(this.getAttribute('href'));
            if(target){
                const offset=80;
                const targetPosition=target.getBoundingClientRect().top+window.pageYOffset-offset;
                window.scrollTo({top:targetPosition,behavior:'smooth'});
            }
        });
    });

    const observerOptions={threshold:0.1,rootMargin:'0px 0px -50px 0px'};
    const observer=new IntersectionObserver(function(entries){
        entries.forEach(entry=>{
            if(entry.isIntersecting){
                entry.target.style.opacity='1';
                entry.target.style.transform='translateY(0)';
            }
        });
    },observerOptions);

    document.querySelectorAll('.feature-card, .step, .arch-node, .tech-item, .req-item').forEach(el=>{
        el.style.opacity='0';
        el.style.transform='translateY(30px)';
        el.style.transition='opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });

    const cards=document.querySelectorAll('.feature-card, .dev-card, .arch-node');
    cards.forEach(card=>{
        card.addEventListener('mousemove',function(e){
            const rect=card.getBoundingClientRect();
            const x=e.clientX-rect.left;
            const y=e.clientY-rect.top;
            const centerX=rect.width/2;
            const centerY=rect.height/2;
            const rotateX=(y-centerY)/20;
            const rotateY=(centerX-x)/20;
            card.style.transform=`perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
        });
        card.addEventListener('mouseleave',function(){
            card.style.transform='perspective(1000px) rotateX(0) rotateY(0) translateY(0)';
        });
    });

    const windowElements=document.querySelectorAll('.window');
    windowElements.forEach((win,i)=>{
        setInterval(()=>{
            const content=win.querySelector('.window-content');
            if(content){
                content.style.opacity=Math.random()*0.3+0.7;
            }
        },2000+i*500);
    });

    const taskbarApps=document.querySelectorAll('.taskbar-apps .app-icon');
    let activeIndex=0;
    setInterval(()=>{
        taskbarApps.forEach((app,i)=>{
            app.classList.remove('active');
            if(i===activeIndex%taskbarApps.length){
                app.classList.add('active');
            }
        });
        activeIndex++;
    },3000);

    const statValues=document.querySelectorAll('.stat-value');
    statValues.forEach(stat=>{
        stat.style.opacity='0';
        stat.style.transform='translateY(20px)';
    });
    setTimeout(()=>{
        statValues.forEach((stat,i)=>{
            setTimeout(()=>{
                stat.style.transition='opacity 0.5s ease, transform 0.5s ease';
                stat.style.opacity='1';
                stat.style.transform='translateY(0)';
            },i*150);
        });
    },500);

    const heroTitle=document.querySelector('.hero h1');
    if(heroTitle){
        heroTitle.style.opacity='0';
        heroTitle.style.transform='translateY(40px)';
        setTimeout(()=>{
            heroTitle.style.transition='opacity 0.8s ease, transform 0.8s ease';
            heroTitle.style.opacity='1';
            heroTitle.style.transform='translateY(0)';
        },200);
    }

    const heroBadge=document.querySelector('.hero-badge');
    if(heroBadge){
        heroBadge.style.opacity='0';
        setTimeout(()=>{
            heroBadge.style.transition='opacity 0.6s ease';
            heroBadge.style.opacity='1';
        },100);
    }

    const buttons=document.querySelectorAll('.btn');
    buttons.forEach(btn=>{
        btn.addEventListener('mousedown',function(){
            this.style.transform='scale(0.98)';
        });
        btn.addEventListener('mouseup',function(){
            this.style.transform='';
        });
        btn.addEventListener('mouseleave',function(){
            this.style.transform='';
        });
    });

    const connectionBeam=document.querySelector('.connection-beam');
    if(connectionBeam){
        setInterval(()=>{
            connectionBeam.style.opacity=Math.random()*0.3+0.7;
        },100);
    }

    let mobileMenuOpen=false;
    const navLinks=document.querySelector('.nav-links');
    if(window.innerWidth<=900&&navLinks){
        const menuBtn=document.createElement('button');
        menuBtn.innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="24" height="24"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>';
        menuBtn.style.cssText='background:none;border:none;color:white;cursor:pointer;padding:8px;display:flex;';
        menuBtn.addEventListener('click',function(){
            mobileMenuOpen=!mobileMenuOpen;
            if(mobileMenuOpen){
                navLinks.style.display='flex';
                navLinks.style.position='absolute';
                navLinks.style.top='64px';
                navLinks.style.left='0';
                navLinks.style.right='0';
                navLinks.style.flexDirection='column';
                navLinks.style.background='rgba(10,10,15,0.98)';
                navLinks.style.padding='24px';
                navLinks.style.gap='16px';
                navLinks.style.borderBottom='1px solid var(--border)';
            }else{
                navLinks.style.display='none';
            }
        });
        document.querySelector('.nav-container').insertBefore(menuBtn,document.querySelector('.nav-btn'));
    }
});
